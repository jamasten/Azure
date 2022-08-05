targetScope = 'subscription'

@description('Determines whether the Image Builder VM will be deployed to custom Virtual Network or use the default Virtual Network.')
param CustomVnet bool = false

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'

@description('The name of the Image Definition for the Shared Image Gallery.')
param ImageDefinitionName string = 'Win10-21h2-VDOT'

@description('The offer of the marketplace image.')
param ImageOffer string = 'office-365'

@description('The publisher of the marketplace image.')
param ImagePublisher string = 'microsoftwindowsdesktop'

@description('The SKU of the marketplace image.')
param ImageSku string = 'win10-21h2-avd-m365-g2'

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

@description('The subnet name for the custom virtual network.')
param SubnetName string = ''

@description('')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The size of the virtual machine used for creating the image.  The recommendation is to use a \'Standard_D2_v2\' size or greater for AVD. https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/14_Building_Images_WVD')
param VirtualMachineSize string = 'Standard_DS2_v2'

@description('The name for the custom virtual network.')
param VirtualNetworkName string = ''

@description('The resource group name for the custom virtual network.')
param VirtualNetworkResourceGroupName string = ''


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


resource resourceGroup 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: 'rg-aib-${Environment}-${LocationShortName}'
  location: Location
  properties: {}
}

resource roleDefinition_Image 'Microsoft.Authorization/roleDefinitions@2015-07-01' = {
  name: guid(subscription().id, 'ImageContributor')
  properties: {
    roleName: 'Image Contributor'
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
        notActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

resource roleDefinition_Network 'Microsoft.Authorization/roleDefinitions@2015-07-01' = if (CustomVnet) {
  name: guid(subscription().id, 'VnetJoin')
  properties: {
    roleName: 'VNET Join'
    description: 'Allow resources to join a subnet'
    permissions: [
      {
        actions: [
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/subnets/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
        ]
        notActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

module imageBuilder 'modules/imageBuilder.bicep' = {
  name: 'ImageBuilder_${Timestamp}'
  scope: resourceGroup
  params: {
    CustomVnet: CustomVnet
    Environment: Environment
    ImageDefinitionName: ImageDefinitionName
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    ImageStorageAccountType: ImageStorageAccountType
    Location: Location
    LocationShortName: LocationShortName
    RoleImageContributor: roleDefinition_Image.name
    RoleVirtualNetworkJoin: roleDefinition_Network.name
    SubnetName: SubnetName
    Timestamp: Timestamp
    VirtualMachineSize: VirtualMachineSize
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
  }
}
