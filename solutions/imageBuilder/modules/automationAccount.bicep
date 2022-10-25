param AutomationAccountName string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageTemplateName string
param Location string
param LogAnalyticsWorkspaceResourceId string
param LogicAppName string
@description('ISO 8601 timestamp used to help determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')
param TimeZone string


var ActionSettingsBody = {
  EnvironmentName: environment().name
  ImagePublisher: ImagePublisher
  ImageOffer: ImageOffer
  ImageSku: ImageSku
  Location: Location
  SubscriptionId: subscription().subscriptionId
  TemplateName: ImageTemplateName
  TemplateResourceGroupName: resourceGroup().name
  TenantId: subscription().tenantId
}
var Modules = [
  {
    name: 'Az.Accounts'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.Accounts'
  }
  {
    name: 'Az.ImageBuilder'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.ImageBuilder'
  }
]
var Runbook = 'AIB-BuildAutomation'
var Webhook = '${Runbook}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'


resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: AutomationAccountName
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

@batchSize(1)
resource modules 'Microsoft.Automation/automationAccounts/modules@2019-06-01' = [for Module in Modules: {
  parent: automationAccount
  name: Module.name
  location: Location
  properties: {
    contentLink: {
      uri: Module.uri
    }
  }
}]

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: Runbook
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/imageBuilder/scripts/New-AzureImageBuilderBuild.ps1'
      version: '1.0.0.0'
    }
  }
  dependsOn: [
    modules
  ]
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: automationAccount
  name: Webhook
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: runbook.name
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
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

module logicApp 'logicApp.bicep' = {
  name: 'LogicApp_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  params: {
    ActionSettingsBody: ActionSettingsBody
    Location: Location
    LogicAppName: LogicAppName
    TimeZone: TimeZone
    WebhookUri: webhook.properties.uri
  }
}


output principalId string = automationAccount.identity.principalId
