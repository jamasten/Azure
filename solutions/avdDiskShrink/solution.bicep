@description('The URL prefix for linked resources.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared Services
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

param FileShareName string

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

param Location string = resourceGroup().location

@description('The stamp index specifies the AVD stamp within an Azure environment.')
param StampIndex int = 0

param StorageAccountName string

param StorageAccountResourceGroupName string

@description('The subnet for the AVD session hosts.')
param SubnetName string

@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')

@description('Virtual network for the AVD sessions hosts')
param VirtualNetworkName string

@description('Virtual network resource group for the AVD sessions hosts')
param VirtualNetworkResourceGroupName string


var AutomationAccountName = 'aa-${NamingStandard}'
var FileSharePath = '\\\\${StorageAccountName}.file.${environment().suffixes.storage}\\${FileShareName}'
var LocationShortName = LocationShortNames[Location]
var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne'
  norwayeast: 'ne2'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southeastasia: 'sa'
  southindia: 'si'
  swedencentral: 'sc'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'ia'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var LogicAppPrefix = 'la-${NamingStandard}'
var NamingStandard = '${Identifier}-${Environment}-${LocationShortName}-${StampIndexFull}'
var RoleAssignmentResourceGroups = [
  StorageAccountResourceGroupName
  VirtualNetworkResourceGroupName
]
var RunbookName = 'FslogixDiskShrink'
var ScriptName = 'Set-FslogixDiskSize.ps1'
var StampIndexFull = padLeft(StampIndex, 2, '0')


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
  name: '${AutomationAccountName}/${RunbookName}'
  location: Location
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: '${_artifactsLocation}${ScriptName}${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  name: '${AutomationAccountName}/${RunbookName}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: RunbookName
    }
  }
  dependsOn:[
    runbook
  ]
}

resource variable 'Microsoft.Automation/automationAccounts/variables@2019-06-01' = {
  name: '${AutomationAccountName}/WebhookURI_${RunbookName}'
  properties: {
    value: '"${webhook.properties.uri}"'
    isEncrypted: false
  }
}

// Gives the Managed Identity for the Automation Account rights to deploy the VM to shrink FSLogix disks
module roleAssignments 'modules/roleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
  }
}]

// Logic App to trigger scaling runbook for the AVD host pool
resource logicApp_ScaleHostPool 'Microsoft.Logic/workflows@2016-06-01' = {
  name: '${LogicAppPrefix}-fslogixDiskShrink-${StorageAccountName}'
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
              FileSharePath: FileSharePath
              StorageAccountName: StorageAccountName
              StorageAccountResourceGroupName: StorageAccountResourceGroupName
              SubnetName: SubnetName
              VirtualNetworkName: VirtualNetworkName
              VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
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
