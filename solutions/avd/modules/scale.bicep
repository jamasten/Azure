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
var LogAnalyticsWorkspaceResourceId = resourceId('Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName)
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
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(resourceGroup().id, 'ScalingContributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module RoleAssignmentForSystemAssignedIdentity './scale_RoleAssignment.bicep' = {
  name: 'RoleAssignmentForSystemAssignedIdentity'
  scope: resourceGroup(SessionHostsResourceGroupName)
  params: {
    AutomationAccountId: automationAccount.identity.principalId
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
