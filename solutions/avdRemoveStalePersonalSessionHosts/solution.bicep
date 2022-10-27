targetScope = 'subscription'


@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

param HostPoolName string

param HostPoolResourceGroupName string

@description('Location for all the deployed resources and resource group.')
param Location string = deployment().location

param MultiHomeMicrosoftMonitoringAgent bool 

@maxValue(730)
@minValue(1)
@description('The number of days until the expiration of an AVD session host.')
param SessionHostExpirationInDays int = 3

param SessionHostsResourceGroupName string

@description('The key / value pairs of metadata for the Azure resources.')
param Tags object = {
}

@description('DO NOT MODIFY THE DEFAULT VALUE!')
param Timestamp string = utcNow('yyyyMMddhhmmss')

param VirtualMachinePrefix string



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

module sessionHosts 'modules/sessionHosts.bicep' = {
  name: 'SessionHosts_${Timestamp}'
  scope: resourceGroup(SessionHostsResourceGroupName)
  params: {
    Location: Location
    LogAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    MultiHomeMicrosoftMonitoringAgent: MultiHomeMicrosoftMonitoringAgent
    Tags: Tags
    Timestamp: Timestamp
    VmName: VirtualMachinePrefix
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
    Location: Location
    LogAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    LogicAppName: LogicAppName
    RunbookName: RunbookName
    Tags: Tags
    Timestamp: Timestamp
  }
}

module roleAssignments 'modules/roleAssignment.bicep' = [for i in range(0, length(RoleAssignments)): {
  name: 'RoleAssignments ${i}_${Timestamp}'
  scope: resourceGroup(RoleAssignments[i].scope)
  params: {
    RoleDefinitionId: RoleAssignments[i].roleDefinitionId
    PrincipalId: automationAccount.outputs.principalId
  }
}]
