targetScope = 'subscription'

@description('The domain name that will be used used for Active Directory. If choosing "None" for DomainServices, use the default value.')
param DomainName string

@allowed([
 'ActiveDirectory' // IaaS
 'AzureActiveDirectory' // PaaS
 'None' // Azure AD
])
@description('The domain services that will be used for kerberos authentication.')
param DomainServices string

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared Services
  't' // Test
])
@description('The environment in which the landing zone will be deployed.')
param Environment string = 'd'

@description('The location where all the resources will be deployed.')
param Location string = deployment().location

@description('Identifier for the deployed infrastructure component.')
param Component array = [
  'id' // identity
  'net' // networking
  'core' // core services
]

@description('WARNING: Do not change the default value!')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The Object ID for the Azure AD User Principal to give admin permissions to the Key Vault')
param UserObjectId string

@description('Local VM password')
@secure()
param VmPassword string

@description('Local VM username')
@secure()
param VmUsername string


var BastionName = 'bastion-${Component[1]}-${Environment}-${LocationShortName}'
var DomainControllerName = 'vm${Component[0]}${Environment}${LocationShortName}dc'
var DomainControllerDiskName = 'disk-${Component[0]}-${Environment}-${LocationShortName}-dc'
var DomainControllerNicName = 'nic-${Component[0]}-${Environment}-${LocationShortName}-dc'
var KeyVaultName = 'kv-${Component[2]}-${Environment}-${LocationShortName}'
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
var LogAnalyticsWorkspaceName = 'law-${Component[2]}-${Environment}-${LocationShortName}'
var ManagedIdentityName = 'uami-${Component[2]}-${Environment}-${LocationShortName}'
var NetworkContributorId = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var NetworkWatcherName = 'nw-${Component[1]}-${Environment}-${LocationShortName}'
var PublicIpAddressName = 'pip-bastion-${Component[1]}${Environment}-${LocationShortName}'
var ResourceGroupNames = [
  'rg-${Component[0]}-${Environment}-${LocationShortName}'
  'rg-${Component[1]}-${Environment}-${LocationShortName}'
  'rg-${Component[2]}-${Environment}-${LocationShortName}'
]
var VnetName = 'vnet-${Component[1]}-${Environment}-${LocationShortName}'


resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for Group in ResourceGroupNames: {
  name: Group
  location: Location
  properties: {}
}]

module managedIdentity './modules/managedIdentity.bicep' = {
  name: 'ManagedIdentityTemplate'
  scope: resourceGroup(ResourceGroupNames[0])
  params: {
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    NetworkContributorId: NetworkContributorId
  }
  dependsOn: [
    resourceGroups
  ]
}

module network './modules/network.bicep' = {
  name: 'NetworkingTemplate'
  scope: resourceGroup(ResourceGroupNames[1])
  params: {
    BastionName: BastionName
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    NetworkContributorId: NetworkContributorId
    NetworkWatcherName: NetworkWatcherName
    PrincipalId: managedIdentity.outputs.principalId
    PublicIpAddressName: PublicIpAddressName
    VnetName: VnetName
  }
  dependsOn: [
    resourceGroups
  ]
}

module identity './modules/identity.bicep' = {
  name: 'DomainServicesTemplate'
  scope: resourceGroup(ResourceGroupNames[0])
  params: {
    DomainControllerName: DomainControllerName
    DomainControllerDiskName: DomainControllerDiskName
    DomainControllerNicName: DomainControllerNicName
    DomainName: DomainName
    DomainServices: DomainServices
    Location: Location
    ResourceGroupNames: ResourceGroupNames
    VmPassword: VmPassword
    VmUsername: VmUsername
    VnetName: VnetName
  }
  dependsOn: [
    network
  ]
}

module dnsFix './modules/dnsFix.bicep' = {
  name: 'DnsFixTemplate'
  scope: resourceGroup(ResourceGroupNames[0])
  params: {
    DomainServices: DomainServices
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    ResourceGroupNames: ResourceGroupNames
    Timestamp: Timestamp
    VnetName: VnetName
  }
  dependsOn: [
    resourceGroups
    network
    identity
  ]
}

module sharedServices './modules/core.bicep' = {
  name: 'SharedServicesTemplate'
  scope: resourceGroup(ResourceGroupNames[2])
  params: {
    DomainName: DomainName
    KeyVaultName: KeyVaultName
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagedIdentityPrincipalId: managedIdentity.outputs.principalId
    UserObjectId: UserObjectId
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
  dependsOn: [
    resourceGroups
  ]
}
