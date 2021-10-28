param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param LogAnalyticsWorkspaceResourceId string
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
    uri: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization'
  }
]
var Runbook = 'WVDAutoScaleRunbookARMBased'
var Variable = 'WebhookURIARMBased'
var Webhook = 'WVDAutoScaleWebhookARMBased'

resource AutomationAccountName_resource 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
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
resource AutomationAccountName_Modules_name 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = [for item in Modules: {
  name: '${AutomationAccountName}/${item.name}'
  location: Location
  properties: {
    contentLink: {
      uri: item.uri
    }
  }
  dependsOn: [
    AutomationAccountName_resource
  ]
}]

resource AutomationAccountName_Runbook 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  parent: AutomationAccountName_resource
  name: '${Runbook}'
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
    AutomationAccountName_Modules_name
  ]
}

resource AutomationAccountName_Webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: AutomationAccountName_resource
  name: '${Webhook}'
  location: Location
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: Runbook
    }
  }
  dependsOn: [
    AutomationAccountName_Modules_name
    AutomationAccountName_Runbook
  ]
}

resource AutomationAccountName_Variable 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  parent: AutomationAccountName_resource
  name: '${Variable}'
  location: Location
  properties: {
    value: '"${AutomationAccountName_Webhook.properties.uri}"'
    isEncrypted: false
  }
  dependsOn: [
    AutomationAccountName_Modules_name
    AutomationAccountName_Runbook
  ]
}

resource diag_AutomationAccountName 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
  scope: AutomationAccountName_resource
  name: 'diag-${AutomationAccountName}'
  location: Location
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
    AutomationAccountName_resource
    AutomationAccountName_Modules_name
  ]
}

resource id_ScalingContributor 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(resourceGroup().id, 'ScalingContributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(AutomationAccountName_resource.id, '2020-01-13-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module RoleAssignmentForSystemAssignedIdentity './nested_RoleAssignmentForSystemAssignedIdentity.bicep' = {
  name: 'RoleAssignmentForSystemAssignedIdentity'
  scope: resourceGroup(SessionHostsResourceGroupName)
  params: {
    AutomationAccountName: AutomationAccountName
    AutomationAccountResourceGroupName: resourceGroup().name
  }
  dependsOn: [
    AutomationAccountName_resource
  ]
}

resource LogicAppName_resource 'Microsoft.Logic/workflows@2016-06-01' = {
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
            uri: replace(reference(AutomationAccountName_Variable.id, '2015-10-31', 'Full').properties.value, '"', '')
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