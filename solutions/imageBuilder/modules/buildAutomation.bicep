param AutomationAccountName string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageTemplateName string
param JobScheduleName string = newGuid()
param Location string
param LogAnalyticsWorkspaceResourceId string
@description('ISO 8601 timestamp used to help determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Time string = utcNow()
param TimeZone string


var EnvironmentName = environment().name
var ImageTemplateResourceGroupName = resourceGroup().name
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
var SubscriptionId = subscription().subscriptionId
var TenantId = subscription().tenantId


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

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: ImageTemplateName
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(Time, 'PT15M')
    timeZone: TimeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: JobScheduleName
  properties: {
    parameters: {
      EnvironmentName: EnvironmentName
      ImagePublisher: ImagePublisher
      ImageOffer: ImageOffer
      ImageSku: ImageSku
      Location: Location
      SubscriptionId: SubscriptionId
      TemplateName: ImageTemplateName
      TemplateResourceGroupName: ImageTemplateResourceGroupName
      TenantId: TenantId
    }
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
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


output principalId string = automationAccount.identity.principalId
