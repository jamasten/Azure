targetScope = 'subscription'


@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The name of the Image Definition for the Shared Image Gallery.')
param ImageDefinitionName string = 'OfficeWorkers-Win11-21h2-g2'

@description('The offer of the marketplace image.')
param ImageOffer string = 'office-365'

@description('The publisher of the marketplace image.')
param ImagePublisher string = 'microsoftwindowsdesktop'

@description('The SKU of the marketplace image.')
param ImageSku string = 'win11-21h2-avd-m365'

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

@description('The name for the storage account containing the scripts & application installers.')
param StorageAccountName string = 'stshdsvcdeu000'

@description('The resource group name for the storage account containing the scripts & application installers.')
param StorageAccountResourceGroupName string = 'rg-shd-svc-d-eu-000'

@description('The name of the container in the storage account containing the scripts & application installers.')
param StorageContainerName string = 'artifacts'

@description('The subnet name for the custom virtual network.')
param SubnetName string = 'Clients'

param Tags object = {}

@description('')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The size of the virtual machine used for creating the image.  The recommendation is to use a \'Standard_D2_v2\' size or greater for AVD. https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD')
param VirtualMachineSize string = 'Standard_DS2_v2'

@description('The name for the custom virtual network.')
param VirtualNetworkName string = 'vnet-shd-net-d-eu-000'

@description('The resource group name for the custom virtual network.')
param VirtualNetworkResourceGroupName string = 'rg-shd-net-d-eu-000'


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
var LocationShortName = LocationShortNames[Location]
var ResourceGroup = 'rg-aib-${Environment}-${LocationShortName}'
var Roles = [
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
]
var StorageUri = 'https://${StorageAccountName}.${environment().suffixes.storage}/${StorageContainerName}/'


resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: ResourceGroup
  location: Location
  tags: Tags
  properties: {}
}

resource roleDefinitions 'Microsoft.Authorization/roleDefinitions@2015-07-01' = [for i in range(0, length(Roles)): {
  name: guid(Roles[i].name, subscription().id)
  properties: {
    roleName: Roles[i].name
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
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: roleDefinitions[i].id
  }
}]

module roleAssignment 'modules/roleAssignments.bicep' = {
  name: 'RoleAssignment_${StorageAccountName}_${Timestamp}'
  scope: resourceGroup(StorageAccountResourceGroupName)
  params: {
    PrincipalId: userAssignedIdentity.outputs.userAssignedIdentityPrincipalId
    RoleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
    StorageAccountName: StorageAccountName
  }
}

module computeGallery 'modules/computeGallery.bicep' = {
  name: 'ComputeGallery_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    ImageDefinitionName: ImageDefinitionName
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
    StorageUri: StorageUri
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.userAssignedIdentityResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
  dependsOn: [
    roleAssignment
    roleAssignments
  ]
}

module imageTemplate 'modules/imageTemplate.bicep' = {
  name: 'ImageTemplate_${Timestamp}'
  scope: rg
  params: {
    Environment: Environment
    ImageDefinitionName: ImageDefinitionName
    ImageDefinitionResourceId: computeGallery.outputs.ImageDefinitionResourceId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageStorageAccountType: ImageStorageAccountType
    ImageVersion: ImageVersion
    Location: Location
    LocationShortName: LocationShortName
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
    roleAssignment
    roleAssignments
  ]
}
