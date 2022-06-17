param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param FslogixStorage string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param LogicAppPrefix string
param MinimumNumberOfRdsh string
@secure()
param SasToken string
param ScriptsUri string
param SessionHostsResourceGroupName string
param SessionThresholdPerCPU string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageResourceGroupName string
param TimeDifference string
@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')


var Environment = environment().name
var ManagementResourceGroupName = resourceGroup().name
var RoleAssignmentResourceGroups = contains(FslogixStorage, 'AzureStorageAccount Premium') ? concat(ScalingResourceGroups, StorageResourceGroup) : ScalingResourceGroups
var Runbooks = contains(FslogixStorage, 'AzureStorageAccount Premium') ? concat(ScalingRunbook, StorageRunbook) : ScalingRunbook
var ScalingResourceGroups = [
  ManagementResourceGroupName
  SessionHostsResourceGroupName
]
var ScalingRunbook = [
  {
    name: 'AvdScaleHostPool'
    script: 'Set-HostPoolScaling.ps1'
  }
]
var StorageResourceGroup = [
  StorageResourceGroupName
]
var StorageRunbook = [
  {
    name: 'AvdScaleFileShareQuota'
    script: 'Set-FileShareScaling.ps1'
  }
]
var SubscriptionId = subscription().subscriptionId


resource runbooks 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = [for i in range(0, length(Runbooks)): {
  name: '${AutomationAccountName}/${Runbooks[i].name}'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${ScriptsUri}${Runbooks[i].script}${SasToken}'
      version: '1.0.0.0'
    }
  }
}]

resource webhooks 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = [for i in range(0, length(Runbooks)): {
  name: '${AutomationAccountName}/${Runbooks[i].name}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: Runbooks[i].name
    }
  }
  dependsOn:[
    runbooks
  ]
}]

resource variables 'Microsoft.Automation/automationAccounts/variables@2019-06-01' = [for i in range(0, length(Runbooks)): {
  name: '${AutomationAccountName}/WebhookURI_${Runbooks[i].name}'
  properties: {
    value: '"${webhooks[i].properties.uri}"'
    isEncrypted: false
  }
}]

// Gives the Automation Account Contributor rights on the Hosts, Management, and Storage resource groups for scaling
module roleAssignments'./scale_RoleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
  }
}]

// Logic App to trigger scaling runbook for the AVD host pool
resource logicApp_ScaleHostPool 'Microsoft.Logic/workflows@2016-06-01' = {
  name: '${LogicAppPrefix}-scalehosts'
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
            uri: replace(variables[0].properties.value, '"', '')
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

// Logic App to trigger scaling runbook for each "officecontainers" file share 
resource logicApp_ScaleFileShares_OfficeContainers 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(StorageIndex, StorageCount): if(contains(FslogixStorage, 'AzureStorageAccount Premium')) {
  name: '${LogicAppPrefix}-${StorageAccountPrefix}${string(i)}-officecontainers'
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
            uri: replace(variables[1].properties.value, '"', '')
            body: {
              Environment: Environment
              FileShareName: 'officecontainers'
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: '${StorageAccountPrefix}${string(i)}'
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

// Logic App to trigger scaling runbook for each "profilecontainers" file share 
resource logicApp_ScaleFileShares_ProfileContainers 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(StorageIndex, StorageCount): if(contains(FslogixStorage, 'AzureStorageAccount Premium')) {
  name: '${LogicAppPrefix}-${StorageAccountPrefix}${string(i)}-profilecontainers'
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
            uri: replace(variables[1].properties.value, '"', '')
            body: {
              Environment: Environment
              FileShareName: 'profilecontainers'
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: '${StorageAccountPrefix}${string(i)}'
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
