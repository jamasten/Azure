targetScope = 'subscription'


@description('Determine whether you want to install Microsoft Project & Visio in the image.')
param DeployProjectVisio bool = false

@description('Determine whether you want to run the Virtual Desktop Optimization Tool on the image.')
param DeployVirtualDesktopOptimizationTool bool = true

@description('Determine whether you want to enable build automation.  This feature will check daily if a new marketplace image exists and will initiate a build if the image date is newer than the last build date.')
param EnableBuildAutomation bool = true

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('Any Azure polices that would affect the AIB build VM should have an exemption for the AIB staging resource group. Common examples are policies that push the Guest Configuration agent or the Microsoft Defender for Endpoint agent. Reference: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-troubleshoot#prerequisites')
param ExemptPolicyAssignmentIds array = []

@description('The name of the Image Definition for the Shared Image Gallery.')
param ImageDefinitionName string = 'Win10-22h2-avd-g2'

@allowed([
  'ConfidentialVM'
  'ConfidentialVMSupported'
  'Standard'
  'TrustedLaunch'
])
@description('The security type for the Image Definition.')
param ImageDefinitionSecurityType string = 'TrustedLaunch'

@description('The offer of the marketplace image.')
param ImageOffer string = 'windows-10'

@description('The publisher of the marketplace image.')
param ImagePublisher string = 'microsoftwindowsdesktop'

@description('The SKU of the marketplace image.')
param ImageSku string = 'win10-22h2-avd-g2'

@description('The version of the marketplace image.')
param ImageVersion string = 'latest'

@description('The storage SKU for the image version replica in the Shared Image Gallery.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param ImageStorageAccountType string = 'Standard_LRS'

@description('The location for the resources deployed in this solution.')
param Location string = deployment().location

@description('The resource ID for the Log Analytics Workspace to store runbook events for bulid automation.')
param LogAnalyticsWorkspaceResourceId string = '/subscriptions/3764b123-4849-4395-8e6e-ca6d68d8d4b4/resourcegroups/rg-shd-svc-d-eu-000/providers/microsoft.operationalinsights/workspaces/law-shd-net-d-eu-000'

@description('The name for the storage account containing the scripts & application installers.')
param StorageAccountName string = 'stshdsvcdeu000'

@description('The resource group name for the storage account containing the scripts & application installers.')
param StorageAccountResourceGroupName string = 'rg-shd-svc-d-eu-000'

@description('The name of the container in the storage account containing the scripts & application installers.')
param StorageContainerName string = 'artifacts'

@description('The subnet name for the custom virtual network.')
param SubnetName string = 'Clients'

param Tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The size of the virtual machine used for creating the image.  The recommendation is to use a \'Standard_D2_v2\' size or greater for AVD. https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD')
param VirtualMachineSize string = 'Standard_D4s_v5'

@description('The name for the custom virtual network.')
param VirtualNetworkName string = 'vnet-shd-net-d-eu-000'

@description('The resource group name for the custom virtual network.')
param VirtualNetworkResourceGroupName string = 'rg-shd-net-d-eu-000'


var AutomationAccountName = 'aa-${NamingStandard}'
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
  chinaeast: 'ce'
  chinaeast2: 'ce2'
  chinanorth: 'cn'
  chinanorth2: 'cn2'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne2'
  norwayeast: 'ne'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southindia: 'si'
  southeastasia: 'sa'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'io'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var ImageTemplateName = 'it-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
var LocationShortName = LocationShortNames[Location]
var NamingStandard = 'aib-${Environment}-${LocationShortName}'
var ResourceGroup = 'rg-${NamingStandard}'
var Roles = union(Roles_Default, Role_AzureCloud)
var Roles_Default = [
  {
    resourceGroup: VirtualNetworkResourceGroupName
    name: 'Virtual Network Join'
    description: 'Allow resources to join a subnet'
    permissions: [
      {
        actions: [
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/subnets/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
          'Microsoft.Network/virtualNetworks/subnets/write' // Required to update the private link network policy
        ]
      }
    ]
  }
  {
    resourceGroup: ResourceGroup
    name: 'Image Template Contributor'
    description: 'Allow the creation and management of images'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/delete'
        ]
      }
    ]
  }
  {
    resourceGroup: ResourceGroup
    name: 'Deployment Script Contributor'
    description: 'Allow Deployment Scripts to deploy required resources to run scripts'
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/*'
          'Microsoft.ContainerInstance/containerGroups/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/deploymentScripts/*'
          'Microsoft.ManagedIdentity/userAssignedIdentities/assign/action'
        ]
      }
    ]
  }
]
var Role_AzureCloud = environment().name == 'AzureCloud' ? [
  {
    resourceGroup: ResourceGroup
    name: 'Image Template Build Automation'
    description: 'Allow Image Template build automation using a Managed Identity on an Automation Account.'
    permissions: [
      {
        actions: [
          'Microsoft.VirtualMachineImages/imageTemplates/run/action'
          'Microsoft.VirtualMachineImages/imageTemplates/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/skus/versions/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/skus/read'
          'Microsoft.Compute/locations/publishers/artifacttypes/offers/read'
          'Microsoft.Compute/locations/publishers/read'
        ]
      }
    ]
  }
] : []
var StagingResourceGroupName = 'rg-aib-staging-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
var StorageUri = 'https://${StorageAccountName}.blob.${environment().suffixes.storage}/${StorageContainerName}/'
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


resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: ResourceGroup
  location: Location
  tags: Tags
  properties: {}
}

resource roleDefinitions 'Microsoft.Authorization/roleDefinitions@2015-07-01' = [for i in range(0, length(Roles)): {
  name: guid(Roles[i].name, subscription().id)
  properties: {
    roleName: '${Roles[i].name} (${subscription().subscriptionId})'
    description: Roles[i].description
    permissions: Roles[i].permissions
    assignableScopes: [
      subscription().id
    ]
  }
}]

module userAssignedIdentity 'modules/userAssignedIdentity.bicep' = {
  name: 'UserAssignedIdentity_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    Location: Location
    LocationShortName: LocationShortName
    Tags: Tags
  }
}

@batchSize(1)
module roleAssignments 'modules/roleAssignments.bicep' = [for i in range(0, length(Roles)): {
  name: 'RoleAssignments_${i}_${Timestamp}'
  scope: resourceGroup(Roles[i].resourceGroup)
  params: {
    PrincipalId: Roles[i].name == 'Image Template Build Automation' ? automationAccount.outputs.principalId : userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: roleDefinitions[i].id
  }
}]

module roleAssignment_Storage 'modules/roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageAccountName}_${Timestamp}'
  scope: resourceGroup(StorageAccountResourceGroupName)
  params: {
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    StorageAccountName: StorageAccountName
  }
}

// Azure US Government requires the Contributor role for the build automation identity until permissions for Microsoft.VirtualMachineImages are supported
module roleAssignment_AzureUSGovernment 'modules/roleAssignments.bicep' = if(environment().name == 'AzureUSGovernment') {
  name: 'RoleAssignment_${rg.name}_${Timestamp}'
  scope: rg
  params: {
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
  }
}

module computeGallery 'modules/computeGallery.bicep' = {
  name: 'ComputeGallery_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    ImageDefinitionName: ImageDefinitionName
    ImageDefinitionSecurityType: ImageDefinitionSecurityType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    Location: Location
    LocationShortName: LocationShortName
    Tags: Tags
  }
}

module networkPolicy 'modules/networkPolicy.bicep' = {
  name: 'NetworkPolicy_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    Location: Location
    LocationShortName: LocationShortName
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.userAssignedIdentityResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    roleAssignment_AzureUSGovernment
    roleAssignment_Storage
    roleAssignments
  ]
}

module imageTemplate 'modules/imageTemplate.bicep' = {
  name: 'ImageTemplate_${Timestamp}'
  scope: rg
  params: {
    DeployProjectVisio: DeployProjectVisio
    DeployVirtualDesktopOptimizationTool: DeployVirtualDesktopOptimizationTool
    ImageDefinitionResourceId: computeGallery.outputs.ImageDefinitionResourceId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageStorageAccountType: ImageStorageAccountType
    ImageTemplateName: ImageTemplateName
    ImageVersion: ImageVersion
    Location: Location
    StagingResourceGroupName: StagingResourceGroupName
    StorageUri: StorageUri
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.userAssignedIdentityResourceId
    VirtualMachineSize: VirtualMachineSize
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    networkPolicy
    roleAssignment_AzureUSGovernment
    roleAssignment_Storage
    roleAssignments
  ]
}

module automationAccount 'modules/buildAutomation.bicep' = if(EnableBuildAutomation) {
  name: 'AutomationAccount_${Timestamp}'
  scope: rg
  params: {
    AutomationAccountName: AutomationAccountName
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageTemplateName: ImageTemplateName
    Location: Location
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    TimeZone: TimeZone
  }
}

module policyExemptions 'modules/exemption.bicep' = [for i in range(0, length(ExemptPolicyAssignmentIds)): if(length(ExemptPolicyAssignmentIds) > 0) {
  name: 'PolicyExemption_${ExemptPolicyAssignmentIds[i]}'
  scope: resourceGroup(StagingResourceGroupName)
  params: {
    PolicyAssignmentId: ExemptPolicyAssignmentIds[i]
  }
}]
