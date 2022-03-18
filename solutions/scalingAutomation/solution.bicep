param AutomationAccountName string
param BeginPeakTime string = '9:00'
param EndPeakTime string = '17:00'
param HostPoolName string
param HostPoolResourceGroupName string
param HostsResourceGroupName string
param LimitSecondsToForceLogOffUser string = '0'
param LogAnalyticsWorkspaceResourceId string = ''
param LogicAppName string
param MinimumNumberOfRdsh string = '0'
param SessionThresholdPerCPU string = '1'
param TimeDifference string = '-5:00'
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
var Location = resourceGroup().location
var RoleAssignmentResourceGroups = [
  HostPoolResourceGroupName
  HostsResourceGroupName
]
var Runbook = 'AvdAutoScale'
var Variable = 'WebhookURI'
var Webhook = 'AvdAutoScale_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'


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

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: Runbook
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/scale.ps1'
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

resource variable 'Microsoft.Automation/automationAccounts/variables@2019-06-01' = {
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

// Gives the Automation Account the Contributor role on the resource groups containing the hosts and host pool
module roleAssignments'./modules/roleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: automationAccount.identity.principalId
  }
}]

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
