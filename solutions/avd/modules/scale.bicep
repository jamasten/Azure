param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param LogAnalyticsWorkspaceName string
param LogicAppName string
param MinimumNumberOfRdsh string
param SessionHostsResourceGroupName string
param SessionThresholdPerCPU string
param TimeDifference string

@description('ISO 8601 timestamp used to help determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')

var ActionSettingsBody = {
  AADTenantId: subscription().tenantId
  SubscriptionId: subscription().subscriptionId
  EnvironmentName: environment().name
  ResourceGroupName: HostPoolResourceGroupName
  HostPoolName: HostPoolName
  MaintenanceTagName: 'Maintenance'
  TimeDifference: TimeDifference
  BeginPeakTime: BeginPeakTime
  EndPeakTime: EndPeakTime
  SessionThresholdPerCPU: SessionThresholdPerCPU
  MinimumNumberOfRDSH: MinimumNumberOfRdsh
  LimitSecondsToForceLogOffUser: LimitSecondsToForceLogOffUser
  LogOffMessageTitle: 'Machine is about to shutdown.'
  LogOffMessageBody: 'Your session will be logged off. Please save and close everything.'
}
var DesktopVirtualizationModule = {
  AzureCloud: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization'
  AzureUSGovernment: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization/3.0.0'
}

var LogAnalyticsWorkspaceResourceId = resourceId('Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName)
var Modules = [
  {
    name: 'Az.Accounts'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.Accounts'
  }
  {
    name: 'Az.Automation'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.Automation'
  }
  {
    name: 'Az.Compute'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.Compute'
  }
  {
    name: 'Az.Resources'
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.Resources'
  }
  {
    name: 'Az.DesktopVirtualization'
    uri: DesktopVirtualizationModule[environment().name]
  }
]
var Runbook = 'WVDAutoScaleRunbookARMBased'
var Variable = 'WebhookURIARMBased'
var Webhook = 'WVDAutoScaleWebhookARMBased_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: '${AutomationAccountName}-scale'
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
resource modules 'Microsoft.Automation/automationAccounts/modules@2019-06-01' = [for item in Modules: {
  parent: automationAccount
  name: item.name
  location: Location
  properties: {
    contentLink: {
      uri: item.uri
    }
  }
}]

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  parent: automationAccount
  name: Runbook
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/scripts/Set-HostPoolScaling.ps1'
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

resource variable 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  parent: automationAccount
  name: Variable
  properties: {
    value: '"${webhook.properties.uri}"'
    isEncrypted: false
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
  dependsOn: [
    modules
  ]
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(resourceGroup().id, 'ScalingContributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(automationAccount.id, '2020-01-13-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module RoleAssignmentForSystemAssignedIdentity './scale_RoleAssignment.bicep' = {
  name: 'RoleAssignmentForSystemAssignedIdentity'
  scope: resourceGroup(SessionHostsResourceGroupName)
  params: {
    AutomationAccountName: automationAccount.name
    AutomationAccountResourceGroupName: resourceGroup().name
  }
}

resource logicApp 'Microsoft.Logic/workflows@2016-06-01' = {
  name: LogicAppName
  location: Location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        HTTP: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: replace(variable.properties.value, '"', '')
            body: ActionSettingsBody
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
}
