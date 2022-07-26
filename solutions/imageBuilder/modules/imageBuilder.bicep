param CustomVnet bool
param ImageDefinitionName string
param ImageDefinitionOffer string
param ImageDefinitionPublisher string
param ImageDefinitionSku string
param ImageDefinitionVersion string
param ImageStorageAccountType string
param Location string
param LocationShortName string
param RoleImageContributor string
param RoleVirtualNetworkJoin string
param SubnetName string
param Timestamp string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


var VmProfileWithoutVnet = {
  vmSize: VirtualMachineSize
}
var VmProfileWithVnet = {
  vmSize: VirtualMachineSize
  vnetConfig: {
    subnetId: resourceId(subscription().subscriptionId, VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
  }
}
var VmProfile = ((SubnetName == '') ? VmProfileWithoutVnet : VmProfileWithVnet)


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uami-imageBuilder-d-${LocationShortName}'
  location: Location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(userAssignedIdentity.name, RoleImageContributor, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleImageContributor)
    principalId: reference(userAssignedIdentity.id, '2018-11-30', 'Full').properties.principalId
    principalType: 'ServicePrincipal'
  }
}

module network 'network.bicep' = if (CustomVnet) {
  name: 'Network_${Timestamp}'
  scope: resourceGroup(VirtualNetworkResourceGroupName)
  params: {
    IdentityName: userAssignedIdentity.name
    ImagingResourceGroupName: resourceGroup().name
    Role: RoleVirtualNetworkJoin
  }
  dependsOn: [
    roleAssignment
  ]
}

resource gallery 'Microsoft.Compute/galleries@2019-03-01' = {
  name: 'sig_d_${LocationShortName}'
  location: Location
  properties: {
    description: ''
    identifier: {}
  }
}

resource image 'Microsoft.Compute/galleries/images@2019-03-01' = {
  parent: gallery
  name: ImageDefinitionName
  location: Location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: ImageDefinitionPublisher
      offer: ImageDefinitionOffer
      sku: ImageDefinitionSku
    }
  }
}

resource imgt_ImageDefinitionName_d_LocationShort 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: 'imgt-${toLower(ImageDefinitionName)}-d-${LocationShortName}'
  location: Location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {
      }
    }
  }
  properties: {
    buildTimeoutInMinutes: 300
    vmProfile: VmProfile
    source: {
      type: 'PlatformImage'
      publisher: ImageDefinitionPublisher
      offer: ImageDefinitionOffer
      sku: ImageDefinitionSku
      version: ImageDefinitionVersion
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'Install Teams'
        runElevated: true
        runAsSystem: true
        scriptUri: 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/imageBuilder/scripts/1_installTeams.ps1'
      }
      {
        type: 'WindowsRestart'
        restartCheckCommand: 'write-host \'restarting post Teams Install\''
        restartTimeout: '5m'
      }
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: image.id
        runOutputName: Timestamp
        artifactTags: {
        }
        replicationRegions: [
          Location
        ]
        storageAccountType: ImageStorageAccountType
      }
    ]
  }
}
