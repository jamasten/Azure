param DiskName string
// param ImageOffer string
// param ImagePublisher string
// param ImageSku string
// param ImageVersion string
param ImageVersionResourceId string
param Location string
param NetworkInterfaceResourceId string
param Tags object
param TrustedLaunch bool
param VmName string
@secure()
param VmPassword string
param VmSize string
@secure()
param VmUsername string


resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: VmName
  location: Location
  tags: Tags
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      imageReference: {
        // publisher: ImagePublisher
        // offer: ImageOffer
        // sku: ImageSku
        // version: ImageVersion
        id: ImageVersionResourceId
      }
      osDisk: {
        name: DiskName
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadOnly'
        deleteOption: 'Delete'
        managedDisk: null
        diffDiskSettings: {
          option: 'Local'
          placement: 'ResourceDisk' // 'CacheDisk'
        }
      }
    }
    osProfile: {
      computerName: VmName
      adminUsername: VmUsername
      adminPassword: VmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NetworkInterfaceResourceId
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      uefiSettings: TrustedLaunch ? {
        secureBootEnabled: true
        vTpmEnabled: true
      } : null
      securityType: TrustedLaunch ? 'TrustedLaunch' : null
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Client'
  }
}
