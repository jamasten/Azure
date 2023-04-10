param Availability string
param AvailabilitySetNamePrefix string
param AvailabilityZones array
param DiskSku string
param DiskEncryptionSetResourceId string
param ImageId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageType string
param ImageVersion string
param Location string
param NetworkInterfaceNamePrefix string
param SessionHostCount int
param SessionHostIndex int
param Tags object
param TrustedLaunch bool
param VirtualMachineIdentity object
param VirtualMachineNamePrefix string
@secure()
param VirtualMachinePassword string
param VirtualMachineSize string
@secure()
param VirtualMachineUsername string


var DiskNamePrefix = 'disk-${VirtualMachineNamePrefix}-'
var DiskEncryptionSetName = empty(DiskEncryptionSetResourceId) ? '' : split(DiskEncryptionSetResourceId, '/')[8]
var DiskEncryptionSetResourceGroupName = empty(DiskEncryptionSetResourceId) ? '' : split(DiskEncryptionSetResourceId, '/')[4]
var ImageReferences = {
  Custom: {
    id: ImageId
  }
  Gallery: {
    publisher: ImagePublisher
    offer: ImageOffer
    sku: ImageSku
    version: ImageVersion
  }
}

resource virtualMachines 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, SessionHostCount): {
  name: '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}'
  location: Location
  tags: Tags
  identity: VirtualMachineIdentity
  zones: Availability == 'AvailabilityZones' ? [
    string(AvailabilityZones[i % length(AvailabilityZones)])
  ] : null
  properties: {
    availabilitySet: Availability == 'AvailabilitySet' ? {
      id: resourceId('Microsoft.Compute/availabilitySets', '${AvailabilitySetNamePrefix}${(i + SessionHostIndex) / 200}')
    } : null
    hardwareProfile: {
      vmSize: VirtualMachineSize
    }
    storageProfile: {
      imageReference: ((ImageType == 'Gallery') ? ImageReferences.Gallery : ImageReferences.Custom)
      osDisk: {
        deleteOption: 'Delete'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: DiskSku
          diskEncryptionSet: !(empty(DiskEncryptionSetResourceId)) ? {
            id: resourceId(DiskEncryptionSetResourceGroupName, 'Microsoft.Compute/diskEncryptionSets', DiskEncryptionSetName)
          } : null
        }
        name: '${DiskNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}'
        osType: 'Windows'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}'
      adminUsername: VirtualMachineUsername
      adminPassword: VirtualMachinePassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${NetworkInterfaceNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}')
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
    licenseType: ((ImagePublisher == 'MicrosoftWindowsServer') ? 'Windows_Server' : 'Windows_Client')
  }
}]
