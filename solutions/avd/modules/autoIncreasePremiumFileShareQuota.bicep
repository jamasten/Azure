param AutomationAccountName string
param FslogixSolution string
param FslogixStorage string
param Location string
param LogicAppPrefix string
@secure()
param SasToken string
param ScriptsUri string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageResourceGroupName string
@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')


var Environment = environment().name
var SubscriptionId = subscription().subscriptionId


resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccountName}/AvdScaleFileShareQuota'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${ScriptsUri}Set-FileShareScaling.ps1${SasToken}'
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  name: '${AutomationAccountName}/${runbook.name}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: runbook.name
    }
  }
}

resource variable 'Microsoft.Automation/automationAccounts/variables@2019-06-01' = {
  name: '${AutomationAccountName}/WebhookURI_${runbook.name}'
  properties: {
    value: '"${webhook.properties.uri}"'
    isEncrypted: false
  }
}

// Gives the Automation Account Contributor rights on the Storage resource group for scaling
module roleAssignments 'roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageResourceGroupName}'
  scope: resourceGroup(StorageResourceGroupName)
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
  }
}

// Logic App to trigger scaling runbook for each "officecontainers" file share 
resource logicApp_ScaleFileShares_OfficeContainers 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(0, StorageCount): if(contains(FslogixSolution, 'Office')) {
  name: '${LogicAppPrefix}-${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}-officecontainers'
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
              Environment: Environment
              FileShareName: 'officecontainers'
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: '${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}'
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
resource logicApp_ScaleFileShares_ProfileContainers 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(0, StorageCount): if(contains(FslogixStorage, 'AzureStorageAccount Premium')) {
  name: '${LogicAppPrefix}-${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}-profilecontainers'
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
              Environment: Environment
              FileShareName: 'profilecontainers'
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: '${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}'
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
