param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string = ''
param DiskName string
param FileShareNames array
param HybridUseBenefit bool
param KeyVaultName string
param Location string
param NicName string
param StorageAccountNames array
param StorageAccountSuffix string
param Subnet string
param Tags object
param Timestamp string = utcNow('yyyyMMddhhmmss')
param UserAssignedIdentityClientId string
param UserAssignedIdentityResourceId string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string
@secure()
param VmPassword string
param VmSize string
@secure()
param VmUsername string


resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: NicName
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: VmName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}' : {}
    }
}
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        deleteOption: 'Delete'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        name: DiskName
      }
      dataDisks: []
    }
    osProfile: {
      computerName: VmName
      adminUsername: VmUsername
      adminPassword: VmPassword
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
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: HybridUseBenefit ? 'Windows_Server' : null
  }
}

resource extension_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${_artifactsLocation}Set-FslogixDiskSize.ps1${_artifactsLocationSasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-FslogixDiskSize.ps1 -FileShareNames ${FileShareNames} -KeyVaultName ${KeyVaultName} -StorageAccountNames ${StorageAccountNames} -StorageAccountSuffix ${StorageAccountSuffix} -UserAssignedIdentityClientId ${UserAssignedIdentityClientId}'
    }
  }
}
