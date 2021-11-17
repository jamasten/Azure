targetScope = 'subscription'
param DomainName string = 'jasonmasten.com'
param Environment string = 'd'
param Instance string = '000'
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
@description('The username portion of the UPN for the principal deploying the script')
param Username string
@description('Azure VM password')
@secure()
param VmPassword string
@description('Azure VM username')
param VmUsername string


var AutomationAccountName = 'aa-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
var BastionName = 'bastion-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
var DomainControllerName = 'vm${UnitDept}${ProjAppSvc[0]}${Environment}${LocationAbbr}dc${Instance}'
var DomainControllerDiskName = 'disk-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}-dc-${Instance}'
var DomainControllerNicName = 'nic-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}-dc-${Instance}'
var KeyVaultName = 'kv-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}'
var LogAnalyticsWorkspaceName = 'law-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
var ManagedIdentityName = 'uami-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
var NetworkContributorId = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var NetworkWatcherName = 'nw-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
var PublicIpAddressName = 'pip-bastion-${UnitDept}-${ProjAppSvc[1]}${Environment}-${LocationAbbr}-${Instance}'
var ResourceGroupNames = [
  'rg-${UnitDept}-${ProjAppSvc[0]}-${Environment}-${LocationAbbr}-${Instance}'
  'rg-${UnitDept}-${ProjAppSvc[1]}-${Environment}-${LocationAbbr}-${Instance}'
  'rg-${UnitDept}-${ProjAppSvc[2]}-${Environment}-${LocationAbbr}-${Instance}'
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

module networks './modules/networks.bicep' = {
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
    Location: Location
    ResourceGroupNames: ResourceGroupNames
    VmPassword: VmPassword
    VmUsername: VmUsername
    VnetName: VnetName
  }
  dependsOn: [
    networks
  ]
}

module dnsFix './modules/dnsFix.bicep' = {
  name: 'DnsAndAdminGroupTemplate'
  scope: resourceGroup(ResourceGroupNames[0])
  params: {
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    ResourceGroupNames: ResourceGroupNames
    Timestamp: Timestamp
    VnetName: VnetName
  }
  dependsOn: [
    resourceGroups
    networks
    identity
  ]
}

module sharedServices './modules/shared.bicep' = {
  name: 'Shared_${Username}_${Timestamp}'
  scope: resourceGroup('rg-shared-${Environment}-${Location}')
  params: {
    AutomationAccountName: AutomationAccountName
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
