param ActionGroupName string
param DeploymentScriptName string
param DistributionGroup string
param Location string
param LogAnalyticsWorkspaceName string
param Tags object
param Time string = utcNow('yyyy-MM-dd-HH-mm-ss')

var Alerts = [
  {
    name: 'Azure Image Builder - Build Failure'
    description: 'Sends an error alert when a build fails on an image template for Azure Image Builder.'
    severity: 0
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image Template build failed"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'Azure Image Builder - Build Success'
    description: 'Sends an informational alert when a build succeeds on an image template for Azure Image Builder.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image Template build succeeded"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: LogAnalyticsWorkspaceName
  location: Location
  tags: Tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: ActionGroupName
  location: 'global'
  tags: Tags
  properties: {
    emailReceivers: [
      {
        emailAddress: DistributionGroup
        name: DistributionGroup
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    groupShortName: 'AIB Builds'
  }
}

// wait for Log Analytics Workspace
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: DeploymentScriptName
  location: Location
  tags: Tags
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.2'
    scriptContent: '''
    Write-Host "Start"
    Get-Date
    Start-Sleep -Seconds 120
    Write-Host "Stop"
    Get-Date
    '''
    cleanupPreference: 'Always'
    forceUpdateTag: Time
    retentionInterval: 'P1D'
    timeout: 'PT10M'
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = [for i in range(0, length(Alerts)): {
  name: Alerts[i].name
  location: Location
  tags: Tags
  kind: 'LogAlert'
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: false
    skipQueryValidation: false
    criteria: Alerts[i].criteria
    description: Alerts[i].description
    displayName: Alerts[i].name
    enabled: true
    evaluationFrequency: Alerts[i].evaluationFrequency
    severity: Alerts[i].severity
    windowSize: Alerts[i].windowSize
    scopes: [
      logAnalyticsWorkspace.id
    ]
  }
  dependsOn: [
    deploymentScript
  ]
}]


output LogAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
