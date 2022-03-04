targetScope = 'subscription'
param DomainName string = 'jasonmasten.us'
@allowed([
 'ActiveDirectory'
 'AzureActiveDirectory'
 'None'
])
param DomainServices string
param Environment string = 'd'
param Location string = 'usgovvirginia'
param LocationAbbr string = 'va'
param ProjAppSvc array = [
  'id'
  'net'
  'svc'
]
param Timestamp string = utcNow('yyyyMMddhhmmss')
param UnitDept string = 'shd'
@description('The Object ID for the Azure AD User Principal to give admin permissions to the Key Vault')
param UserObjectId string
@description('Azure VM password')
@secure()
param VmPassword string
@description('Azure VM username')
param VmUsername string


var BastionName = 'bastion-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'
var DomainControllerName = 'vm${UnitDept}${ProjAppSvc[0]}${Environment}${LocationAbbr}dc'
var DomainControllerDiskName = 'disk-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}-dc'
var DomainControllerNicName = 'nic-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}-dc'
var KeyVaultName = 'kv-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}'
var LogAnalyticsWorkspaceName = 'law-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'
var ManagedIdentityName = 'uami-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'
var NetworkContributorId = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var NetworkWatcherName = 'nw-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'
var PublicIpAddressName = 'pip-bastion-${UnitDept}-${ProjAppSvc[1]}${Environment}-${LocationAbbr}'
var ResourceGroupNames = [
  'rg-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}'
  'rg-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'
  'rg-${UnitDept}-${ProjAppSvc[2]}-${Environment}-${LocationAbbr}'
]
var VnetName = 'vnet-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}'


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

module sharedServices './modules/shared.bicep' = {
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
