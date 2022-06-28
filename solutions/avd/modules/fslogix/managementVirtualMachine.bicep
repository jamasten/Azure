param DiskEncryption bool
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param KeyVaultName string
param Location string
param ManagementVmName string
param NamingStandard string
param ResourceGroups array
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string


var DeploymentResourceGroup = ResourceGroups[0] // Deployment Resource Group
var ManagementResourceGroup = ResourceGroups[2] // Management Resource Group
var NicName = 'nic-${NamingStandard}-mgt'


resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
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

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: ManagementVmName
  location: Location
  tags: Tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
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
          storageAccountType: 'Standard_LRS'
        }
        name: 'disk-${NamingStandard}-mgt'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: ManagementVmName
      adminUsername: VmUsername
      adminPassword: VmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
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
    licenseType: 'Windows_Server'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: vm
  name: 'JsonADDomainExtension'
  location: Location
  tags: Tags
  properties: {
    forceUpdateTag: Timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: DomainName
      User: DomainJoinUserPrincipalName
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
}

resource extension_AzureDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = if(DiskEncryption) {
  parent: vm
  name: 'AzureDiskEncryption'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: DiskEncryption ? reference(resourceId(ManagementResourceGroup, 'Microsoft.KeyVault/vaults', KeyVaultName), '2016-10-01', 'Full').properties.vaultUri : null
      KeyVaultResourceId: resourceId(ManagementResourceGroup, 'Microsoft.KeyVault/vaults', KeyVaultName)
      KeyEncryptionKeyURL: DiskEncryption ? reference(resourceId(DeploymentResourceGroup, 'Microsoft.Resources/deploymentScripts', 'ds-${NamingStandard}-bitlockerKek'), '2019-10-01-preview', 'Full').properties.outputs.text : null
      KekVaultResourceId: resourceId(ManagementResourceGroup, 'Microsoft.KeyVault/vaults', KeyVaultName)
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
  dependsOn: [
    extension_JsonADDomainExtension
  ]
}
