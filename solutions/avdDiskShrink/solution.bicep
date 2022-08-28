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

@description('The names of the files shares containing the FSLogix containers.')
param FileShareNames array = [
  'officecontainers'
  'profilecontainers'
]

@description('Choose whether to enable the Hybrid Use Benefit on the virtual machine.  This is only valid you have appropriate licensing with Software Assurance. https://docs.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit')
param HybridUseBenefit bool

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

param Location string = resourceGroup().location

@description('The stamp index specifies the AVD stamp within an Azure environment.')
param StampIndex int = 0

@description('The names of the Azure Storage Accounts containing the file shares for FSLogix.')
param StorageAccountNames array

@description('The names of the Azure Resource Groups containing the Azure Storage Accounts. A resource group must be listed for each Storage Account even if the same Resource Group is listed multiple times.')
param StorageAccountResourceGroupNames array

@description('The subnet for the AVD session hosts.')
param SubnetName string

param Tags object = {

}

@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')

@description('Virtual network for the AVD sessions hosts')
param VirtualNetworkName string

@description('Virtual network resource group for the AVD sessions hosts')
param VirtualNetworkResourceGroupName string

@secure()
param VmPassword string

param VmSize string

@secure()
param VmUsername string


var AutomationAccountName = 'aa-${NamingStandard}'
var KeyVaultName = 'kv-${NamingStandard}'
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
var RoleAssignmentResourceGroups = union([
  VirtualNetworkResourceGroupName
], StorageAccountResourceGroupNames)
var RunbookName = 'FslogixDiskShrink'
var ScriptName = 'Set-FslogixDiskSize.ps1'
var StampIndexFull = padLeft(StampIndex, 2, '0')
var TemplateSpecName = 'ts-${NamingStandard}'


resource templateSpec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: TemplateSpecName
  location: Location
  properties: {
    description: 'Deploys a virtual machine to run the "FSLogix Disk Shrink" tool against an SMB share containing FSLogix profile containers.'
    displayName: 'FSLogix Disk Shrink solution'
  }
}

resource templateSpecVersion 'Microsoft.Resources/templateSpecs/versions@2021-05-01' = {
  parent: templateSpec
  name: '1.0'
  location: Location
  properties: {
    mainTemplate: loadJsonContent('modules/templateSpecVersion.json')
  }
}

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
@batchSize(1)
module roleAssignments 'modules/roleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: KeyVaultName
  location: Location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(resourceId('Microsoft.Automation/automationAccounts', AutomationAccountName), '2021-06-22', 'Full').identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
  dependsOn: []
}

resource secret_VmPassword 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVault
  name: 'VmPassword'
  properties: {
    value: VmPassword
  }
}

resource secret_VmUsername 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVault
  name: 'VmUsername'
  properties: {
    value: VmUsername
  }
}

// Logic App to trigger scaling runbook for the AVD host pool
resource logicApp 'Microsoft.Logic/workflows@2016-06-01' = {
  name: '${LogicAppPrefix}-fds'
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
              _artifactsLoction: _artifactsLocation
              _artifactsLocationSasToken: _artifactsLocationSasToken
              Environment: Environment
              FileShareNames: FileShareNames
              HybridUseBenefit: HybridUseBenefit
              Identifier: Identifier
              LocationShortName: LocationShortName
              Location: Location
              StampIndexFull: StampIndexFull
              StorageAccountNames: StorageAccountNames
              StorageAccountResourceGroupNames: StorageAccountResourceGroupNames
              SubnetName: SubnetName
              SubscriptionId: subscription().subscriptionId
              Tags: Tags
              TemplateSpecId: templateSpecVersion.id
              TenantId: subscription().tenantId
              VirtualNetworkName: VirtualNetworkName
              VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
              VmSize: VmSize
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
  dependsOn: [
    roleAssignments
  ]
}
