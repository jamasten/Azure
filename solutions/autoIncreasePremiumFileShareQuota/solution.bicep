@description('The URL prefix for linked resources.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/autoIncreasePremiumFileShareQuota/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@description('The name of the Azure Automation Account.')
param AutomationAccountName string

@description('The names of the files shares on Azure Files Premium.')
param FileShareNames array

@description('The Azure deployment location for the Azure resources.')
param Location string

@description('The name prefix of the Logic App used to trigger the runbook in the Automation Account.')
param LogicAppPrefix string

@description('The name of the Azure Storage Account with Azure Files Premium.')
param StorageAccountName string

@description('The resource group name of the Azure Storage Account with Azure Files Premium.')
param StorageResourceGroupName string

@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')


var Environment = environment().name
var StorageAccountContributor = '17d1049b-9a84-46fb-8f53-869881c3d3ab'
var SubscriptionId = subscription().subscriptionId


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
  name: 'AvdScaleFileShareQuota'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${_artifactsLocation}Set-FileShareScaling.ps1${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: automationAccount
  name: '${runbook.name}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: runbook.name
    }
  }
}

// Assigns the System Assigned Managed Identity on the Automation Account the Storage Account Contributor role on the storage resource group to support scaling
module roleAssignments 'modules/roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageResourceGroupName}'
  scope: resourceGroup(StorageResourceGroupName)
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
    RoleDefinitionId: StorageAccountContributor
  }
}

// Logic App to trigger the scaling runbook for each file share 
resource logicApps 'Microsoft.Logic/workflows@2016-06-01' = [for i in range(0, length(FileShareNames)): {
  name: '${LogicAppPrefix}-${StorageAccountName}-${FileShareNames[i]}'
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
            uri: webhook.properties.uri
            body: {
              Environment: Environment
              FileShareName: FileShareNames[i]
              ResourceGroupName: StorageResourceGroupName
              StorageAccountName: StorageAccountName
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
