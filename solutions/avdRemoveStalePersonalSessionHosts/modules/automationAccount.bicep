param AutomationAccountName string
param Location string
param LogAnalyticsWorkspaceResourceId string
param LogicAppName string
param RunbookName string
param StorageContainerUri string
param Tags object
param Timestamp string
@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp2 string = utcNow('u')


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

resource diagnosticsSetting 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
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

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: RunbookName
  location: Location
  tags: Tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: ''
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: automationAccount
  name: '${RunbookName}_${Timestamp}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp2, 'P5Y')
    runbook: {
      name: runbook.name
    }
  }
}

module logicApp 'logicApp.bicep' = {
  name: 'LogicApp'
  params: {
    Location: Location
    LogicAppName: LogicAppName
    Tags: Tags
    WebhookUri: webhook.properties.uri
  }
}


output principalId string = automationAccount.identity.principalId
