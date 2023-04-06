@description('The URL prefix for linked resources.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/fslogixDiskShrinkAutomation/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

param DeleteOlderThanDays int

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared Services
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The names of the files shares containing the FSLogix containers.')
param FileShareResourceIds array = [
  
]

@description('Choose whether to enable the Hybrid Use Benefit on the virtual machine.  This is only valid you have appropriate licensing with Software Assurance. https://docs.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit')
param HybridUseBenefit bool = false

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

param JobScheduleName string = newGuid()

param Location string = resourceGroup().location


@description('The date and time the tool should run weekly. Ideally select a time when most or all users will offline.')
param RecurrenceDateTime string = '2022-08-27T23:00:00'

@description('The stamp index specifies the AVD stamp within an Azure environment.')
param StampIndex int = 0

@description('The names of the Azure Storage Accounts containing the file shares for FSLogix.')
param StorageAccountNames array = [
  'stfspeovad0000'
]

@description('The names of the Azure Resource Groups containing the Azure Storage Accounts. A resource group must be listed for each Storage Account even if the same Resource Group is listed multiple times.')
param StorageAccountResourceGroupNames array = [
  'rg-fs-peo-va-d-storage-00'
]

@description('The subnet for the AVD session hosts.')
param SubnetName string = 'Clients'

param Tags object = {
  Purpose: 'Fslogix Disk Shrink tool'
}

param Time string = utcNow()

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('Virtual network for the virtual machine to run the tool.')
param VirtualNetworkName string = 'vnet-shd-net-d-va'

@description('Virtual network resource group for the virtual machine to run the tool.')
param VirtualNetworkResourceGroupName string = 'rg-shd-net-d-va'

@secure()
param VmPassword string

param VmSize string = 'Standard_D4s_v4'

@secure()
param VmUsername string

@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param WebhookTimestamp string = utcNow('u')


var AutomationAccountName = 'aa-${NamingStandard}'
var DiskName = 'disk-${NamingStandard}'
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
var NamingStandard = '${Identifier}-${Environment}-${LocationShortName}-${StampIndexFull}-fds'
var NicName = 'nic-${NamingStandard}'
var RoleAssignmentResourceGroups = union([
  resourceGroup().name
  VirtualNetworkResourceGroupName
], StorageAccountResourceGroupNames)
var RoleDefinitionIds = {
  KeyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  ManagedIdentityOperator: 'f1a07417-d97a-45cb-824c-7a7467783830'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}
var RunbookName = 'FslogixDiskShrink'
var RunbookScriptName = 'Set-FslogixDiskShrinkVirtualMachine.ps1'
var StampIndexFull = padLeft(StampIndex, 2, '0')
var StorageAccountSuffix = environment().suffixes.storage
var TemplateSpecName = 'ts-${NamingStandard}'
var TimeZone = TimeZones[Location]
var TimeZones = {
  australiacentral: 'AUS Eastern Standard Time'
  australiacentral2: 'AUS Eastern Standard Time'
  australiaeast: 'AUS Eastern Standard Time'
  australiasoutheast: 'AUS Eastern Standard Time'
  brazilsouth: 'E. South America Standard Time'
  brazilsoutheast: 'E. South America Standard Time'
  canadacentral: 'Eastern Standard Time'
  canadaeast: 'Eastern Standard Time'
  centralindia: 'India Standard Time'
  centralus: 'Central Standard Time'
  chinaeast: 'China Standard Time'
  chinaeast2: 'China Standard Time'
  chinanorth: 'China Standard Time'
  chinanorth2: 'China Standard Time'
  eastasia: 'China Standard Time'
  eastus: 'Eastern Standard Time'
  eastus2: 'Eastern Standard Time'
  francecentral: 'Central Europe Standard Time'
  francesouth: 'Central Europe Standard Time'
  germanynorth: 'Central Europe Standard Time'
  germanywestcentral: 'Central Europe Standard Time'
  japaneast: 'Tokyo Standard Time'
  japanwest: 'Tokyo Standard Time'
  jioindiacentral: 'India Standard Time'
  jioindiawest: 'India Standard Time'
  koreacentral: 'Korea Standard Time'
  koreasouth: 'Korea Standard Time'
  northcentralus: 'Central Standard Time'
  northeurope: 'GMT Standard Time'
  norwayeast: 'Central Europe Standard Time'
  norwaywest: 'Central Europe Standard Time'
  southafricanorth: 'South Africa Standard Time'
  southafricawest: 'South Africa Standard Time'
  southcentralus: 'Central Standard Time'
  southindia: 'India Standard Time'
  southeastasia: 'Singapore Standard Time'
  swedencentral: 'Central Europe Standard Time'
  switzerlandnorth: 'Central Europe Standard Time'
  switzerlandwest: 'Central Europe Standard Time'
  uaecentral: 'Arabian Standard Time'
  uaenorth: 'Arabian Standard Time'
  uksouth: 'GMT Standard Time'
  ukwest: 'GMT Standard Time'
  usdodcentral: 'Central Standard Time'
  usdodeast: 'Eastern Standard Time'
  usgovarizona: 'Mountain Standard Time'
  usgoviowa: 'Central Standard Time'
  usgovtexas: 'Central Standard Time'
  usgovvirginia: 'Eastern Standard Time'
  westcentralus: 'Mountain Standard Time'
  westeurope: 'Central Europe Standard Time'
  westindia: 'India Standard Time'
  westus: 'Pacific Standard Time'
  westus2: 'Pacific Standard Time'
  westus3: 'Mountain Standard Time'
}
var UserAssignedIdentityName = 'uai-${NamingStandard}'
var VmName = 'vm${Identifier}${Environment}${LocationShortName}${StampIndexFull}fds'


// The User Assigned Identity is attached to the virtual machine when its deployed so it has access to grab Key Vault secrets
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: UserAssignedIdentityName
  location: Location
}

// The Template Spec is deployed by the Automation Runbook to create the virtual machine and run the tool
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

// The Automation Account stores the runbook that kicks off the tool
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

// The Runbook orchestrates the deployment and manages the resources to run the tool
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: RunbookName
  location: Location
  properties: {
    description: 'FSLogix Disk Shrink Automation'
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: '${_artifactsLocation}${RunbookScriptName}${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

// Gives the Managed Identity for the Automation Account rights to deploy the VM to shrink FSLogix disks
@batchSize(1)
module roleAssignments_VirtualMachineContributor 'modules/roleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    AutomationAccountId: automationAccount.identity.principalId
  }
}]

// Gives the Managed Identity for the Automation Account rights to deploy the Template Spec
resource roleAssignment_Reader 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(automationAccount.id, RoleDefinitionIds.Reader, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.Reader)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Gives the Managed Identity for the Automation Account rights to add the User Assigned Idenity to the virtual machine
resource roleAssignment_ManagedIdentityOperator 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(automationAccount.id, RoleDefinitionIds.ManagedIdentityOperator, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.ManagedIdentityOperator)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// The Key Vault stores the secrets to deploy virtual machine and mount the SMB share(s)
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: KeyVaultName
  location: Location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: false
    publicNetworkAccess: 'Enabled'
  }
  dependsOn: []
}

// Key Vault Secret for the SAS token on the storage account or container
resource secret_SasToken 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = if(!empty(_artifactsLocationSasToken)) {
  parent: keyVault
  name: 'SasToken'
  properties: {
    value: _artifactsLocationSasToken
  }
}

// Key Vault Secrets for the Storage Account keys so the SMB share can be mounted as an admin on the virtual machine
module secrets_StorageAccountKeys 'modules/storageAccountKeys.bicep' = [for i in range(0, length(StorageAccountNames)): {
  name: 'KeyVaultSecret_${StorageAccountNames[i]}_${Timestamp}'
  //scope: resourceGroup(StorageAccountResourceGroupNames[i])
  params: {
    KeyVaultName: keyVault.name
    StorageAccount: StorageAccountNames[i]
    StorageAccountResourceGroup: StorageAccountResourceGroupNames[i]
  }
}]

// Key Vault Secret for the local admin password on the virtual machine
resource secret_VmPassword 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVault
  name: 'VmPassword'
  properties: {
    value: VmPassword
  }
}

// Key Vault Secret for the local admin username on the virtual machine
resource secret_VmUsername 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVault
  name: 'VmUsername'
  properties: {
    value: VmUsername
  }
}

// Gives the Managed Identity for the Automation Account rights to get key vault secrects
resource roleAssignment_KeyVaultSecretsUser01 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(automationAccount.id, RoleDefinitionIds.KeyVaultSecretsUser, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.KeyVaultSecretsUser)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Gives the User Assigned Identity rights to get key vault secrets
resource roleAssignment_KeyVaultSecretsUser02 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentity.id, RoleDefinitionIds.KeyVaultSecretsUser, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.KeyVaultSecretsUser)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: '${StorageAccountName}_${FileShareName}'
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(Time, 'PT15M')
    timeZone: TimeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  name: JobScheduleName
  properties: {
    parameters: {
      _artifactsLoction: _artifactsLocation
      DeleteOlderThanDays: DeleteOlderThanDays
      Environment: environment().name
      FileShareNames: join(FileShareNames, ',')
      HybridUseBenefit: HybridUseBenefit
      KeyVaultName: keyVault.name
      Location: Location
      NicName: NicName
      ResourceGroupName: resourceGroup().name
      StorageAccountNames: join(StorageAccountNames, ',')
      StorageAccountSuffix: StorageAccountSuffix
      SubnetName: SubnetName
      SubscriptionId: subscription().subscriptionId
      Tags: Tags
      TemplateSpecId: templateSpecVersion.id
      TenantId: subscription().tenantId
      UserAssignedIdentityClientId: userAssignedIdentity.properties.clientId
      UserAssignedIdentityResourceId: userAssignedIdentity.id
      VirtualNetworkName: VirtualNetworkName
      VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
      VmName: VmName
      VmSize: VmSize
    }
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
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
