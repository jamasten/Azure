@description('The name of the action group for sending emails to a distribution group.')
param ActionGroupName string = ''

@description('The URL prefix for linked resources.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/autoIncreasePremiumFileShareQuota/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@description('The name of the Azure Automation Account.')
param AutomationAccountName string

@description('The distribution group to send alerts to when the file share quota increases.')
param DistributionGroup string = ''

@description('The names of the files shares on Azure Files Premium.')
param FileShareNames array

@description('The Azure deployment location for the Azure resources.')
param Location string = resourceGroup().location

@description('The resource ID for the Log Analytics Workspace to collect runbook logs for alerting and dashboards.')
param LogAnalyticsWorkspaceResourceId string = ''

@description('The name prefix of the Logic App used to trigger the runbook in the Automation Account.')
param LogicAppPrefix string

@description('The name of the Azure Storage Account with Azure Files Premium.')
param StorageAccountName string

@description('The resource group name of the Azure Storage Account with Azure Files Premium.')
param StorageResourceGroupName string

@description('The tags are metadata that will be appended to each Azure resource.')
param Tags object = {}

@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')

var Environment = environment().name
var StorageAccountContributor = '17d1049b-9a84-46fb-8f53-869881c3d3ab'
var SubscriptionId = subscription().subscriptionId

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: AutomationAccountName
  location: Location
  tags: Tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

// Enables the collection of the runbook logs in Log Analytics for alerting and dashboards
resource diagnosticSetting 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
  name: ActionGroupName
  tags: Tags
  location: 'global'
  properties: {
    groupShortName: 'EmailAlerts'
    enabled: true
    emailReceivers: [
      {
        name: DistributionGroup
        emailAddress: DistributionGroup
        useCommonAlertSchema: true
      }
    ]
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
  name: 'Premium File Share Quota Increased'
  location: Location
  tags: Tags
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
      customProperties: {}
    }
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Increasing the file share quota"'
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
    displayName: 'Premium File Share Quota Increased'
    description: 'Sends an informational alert when the Runbook in the Automation Account increases the quota on a file share in Azure Files Premium.'
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      LogAnalyticsWorkspaceResourceId
    ]
    severity: 3
    windowSize: 'PT5M'
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: 'AvdScaleFileShareQuota'
  location: Location
  tags: Tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${_artifactsLocation}Set-FileShareScaling.ps1${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: automationAccount
  name: '${runbook.name}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: runbook.name
    }
  }
}

// Assigns the System Assigned Managed Identity on the Automation Account the Storage Account Contributor role on the storage resource group to support scaling
module roleAssignments 'modules/roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageResourceGroupName}'
  scope: resourceGroup(StorageResourceGroupName)
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
    RoleDefinitionId: StorageAccountContributor
  }
}

// Logic App to trigger the scaling runbook for each file share 
resource logicApps 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(0, length(FileShareNames)): {
  name: '${LogicAppPrefix}-${StorageAccountName}-${FileShareNames[i]}'
  location: Location
  tags: Tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        HTTP: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: webhook.properties.uri
            body: {
              Environment: Environment
              FileShareName: FileShareNames[i]
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: StorageAccountName
              SubscriptionId: SubscriptionId
            }
          }
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Minute'
            interval: 15
          }
        }
      }
    }
  }
}]
