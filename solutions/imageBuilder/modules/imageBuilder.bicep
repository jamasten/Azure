param CustomVnet bool
param Environment string
param ImageDefinitionName string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageStorageAccountType string
param ImageVersion string
param Location string
param LocationShortName string
param RoleImageContributor string
param RoleVirtualNetworkJoin string
param SubnetName string
param Timestamp string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uai-aib-${Environment}-${LocationShortName}'
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

module network 'network.bicep' = if(CustomVnet) {
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

resource gallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: 'cg_aib_${Environment}_${LocationShortName}'
  location: Location
}

resource image 'Microsoft.Compute/galleries/images@2022-01-03' = {
  parent: gallery
  name: ImageDefinitionName
  location: Location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: contains(ImageSku, '-g2') ? 'V2' : 'V1'
    identifier: {
      publisher: ImagePublisher
      offer: ImageOffer
      sku: ImageSku
    }
  }
}

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: 'imgt-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
  location: Location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {
      }
    }
  }
  properties: {
    stagingResourceGroup: '/subscriptions/${subscription().subscriptionId}/resourceGroups/rg-aib-staging-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
    buildTimeoutInMinutes: 300
    vmProfile: {
      vmSize: VirtualMachineSize
      vnetConfig: !empty(SubnetName) ? {
        subnetId: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
      } : null
    }
    source: {
      type: 'PlatformImage'
      publisher: ImagePublisher
      offer: ImageOffer
      sku: ImageSku
      version: ImageVersion
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'Virtual Desktop Optimization Tool'
        runElevated: true
        runAsSystem: true
        scriptUri: 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/imageBuilder/scripts/vdot.ps1'
      }
      {
        type: 'WindowsRestart'
        restartCheckCommand: 'write-host \'Restarting post VDOT\''
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
        artifactTags: {}
        replicationRegions: [
          Location
        ]
        storageAccountType: ImageStorageAccountType
      }
    ]
  }
}
