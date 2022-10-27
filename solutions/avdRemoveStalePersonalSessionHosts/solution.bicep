targetScope = 'subscription'


@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The name of the AVD host pool to manage stale session hosts.')
param HostPoolName string

@description('The name of the resource group for the AVD host pool to manage stale session hosts.')
param HostPoolResourceGroupName string

@description('Location for all the deployed resources and resource group.')
param Location string = deployment().location

@maxValue(730)
@minValue(1)
@description('The number of days until an AVD session host expires.')
param SessionHostExpirationInDays int = 1

@description('The key / value pairs of metadata for the Azure resources.')
param Tags object = {
}

@description('DO NOT MODIFY THE DEFAULT VALUE!')
param Timestamp string = utcNow('yyyyMMddhhmmss')


var AutomationAccountName = 'aa-${NamingStandard}'
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
var LogicAppName = 'la-${NamingStandard}'
var LogAnalyticsWorkspaceName = 'law-${NamingStandard}'
var NamingStandard = 'avd-staleHostsMgmt-${Environment}-${LocationShortName}'
var ResourceGroupName = 'rg-${NamingStandard}'
var RoleAssignments = [
  {
    scope: HostPoolResourceGroupName
    roleDefinitionId: 'a959dbd1-f747-45e3-8ba6-dd80f235f97c' //Desktop Virtualization Virtual Machine Contributor
  }
  {
    scope: ResourceGroupName
    roleDefinitionId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05' // Monitoring Reader
  }
]
var RunbookName = 'RemoveExpiredSessionHosts'
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


resource rg 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroupName
  location: Location
  tags: Tags
}

module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = {
  name: 'LogAnalyticsWorkspace_${Timestamp}'
  scope: rg
  params: {
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    SessionHostExpirationInDays: SessionHostExpirationInDays
    Tags: Tags
  }
}

module hostPool 'modules/hostPool.bicep' = {
  name: 'HostPool_${Timestamp}'
  scope: resourceGroup(HostPoolResourceGroupName)
  params: {
    HostPoolName: HostPoolName
    LogAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    NamingStandard: NamingStandard
  }
}

module automationAccount 'modules/automationAccount.bicep' = {
  name: 'AutomationAccount_${Timestamp}'
  scope: rg
  params: {
    AutomationAccountName: AutomationAccountName
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: HostPoolResourceGroupName
    Location: Location
    LogAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    LogicAppName: LogicAppName
    RunbookName: RunbookName
    SessionHostExpirationInDays: SessionHostExpirationInDays
    Tags: Tags
    Timestamp: Timestamp
    TimeZone: TimeZone
    WorkspaceId: logAnalyticsWorkspace.outputs.workspaceId
  }
}

module roleAssignments 'modules/roleAssignment.bicep' = [for i in range(0, length(RoleAssignments)): {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(RoleAssignments[i].scope)
  params: {
    RoleDefinitionId: RoleAssignments[i].roleDefinitionId
    PrincipalId: automationAccount.outputs.principalId
  }
}]
