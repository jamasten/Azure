param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param LogicAppPrefix string
param ManagementResourceGroupName string
param MinimumNumberOfRdsh string
@secure()
param SasToken string
param ScriptsUri string
param SessionHostsResourceGroupName string
param SessionThresholdPerCPU string
param TimeDifference string
@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')


var RoleAssignmentResourceGroups = [
  ManagementResourceGroupName
  SessionHostsResourceGroupName
]


resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccountName}/AvdScaleHostPool'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${ScriptsUri}Set-HostPoolScaling.ps1${SasToken}'
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  name: '${AutomationAccountName}/AvdScaleHostPool_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: 'AvdScaleHostPool'
    }
  }
  dependsOn:[
    runbook
  ]
}

resource variable 'Microsoft.Automation/automationAccounts/variables@2019-06-01' = {
  name: '${AutomationAccountName}/WebhookURI_AvdScaleHostPool'
  properties: {
    value: '"${webhook.properties.uri}"'
    isEncrypted: false
  }
}

// Gives the Automation Account Contributor rights on the Hosts and Management resource groups for scaling
module roleAssignments'./scale_RoleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
  }
}]

// Logic App to trigger scaling runbook for the AVD host pool
resource logicApp_ScaleHostPool 'Microsoft.Logic/workflows@2016-06-01' = {
  name: '${LogicAppPrefix}-scaleHostPool'
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
            body: {
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
