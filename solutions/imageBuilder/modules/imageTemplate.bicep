param Environment string
param ImageDefinitionName string
param ImageDefinitionResourceId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageStorageAccountType string
param ImageVersion string
param Location string
param LocationShortName string
param StorageAccountName string
param StorageContainerName string
param SubnetName string
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


var StorageUri = 'https://${StorageAccountName}.${environment().suffixes.storage}/${StorageContainerName}/'


resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: 'imgt-${toLower(ImageDefinitionName)}-${Environment}-${LocationShortName}'
  location: Location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {
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
        scriptUri: '${StorageUri}vdot.ps1'
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
        galleryImageId: ImageDefinitionResourceId
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
