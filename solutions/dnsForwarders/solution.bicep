@description('The name for the availability set')
param AvSetName string = 'av-dns-p-eus'

@description('The name prefix for the disks on the virtual machines. A number will be added as a suffix based on the copy loop number.')
param DiskNamePrefix string = 'disk-dns-p-eus-'

@description('Storage SKU for the disks on the virtual machines.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param DiskSku string = 'Standard_LRS'

@description('Forwarder IP Address for the DNS servers.')
param DnsForwarderIPAddress array = [
  '10.0.0.4'
]

@description('The domain name used to join virtual machines to the domain.')
param DomainName string = 'jasonmasten.com'

@description('Password for the privileged account to domain join virtual machines.')
@secure()
param DomainPassword string

@description('Username for the privileged account to domain join virtual machines.')
param DomainUsername string

@description('Conditionally deploys the VM with the Hybrid Use Benefit for Windows Server.')
@allowed([
  'yes'
  'no'
])
param HybridUseBenefit string = 'no'

@description('The offer of the OS image to use for the virtual machine resource.')
param ImageOffer string = 'WindowsServer'

@description('The publisher of the OS image to use for the virtual machine resource.')
param ImagePublisher string = 'MicrosoftWindowsServer'

@description('The sku of the OS image to use for the virtual machine resource.')
param ImageSku string = '2019-Datacenter-Core'

@description('The version of the OS image to use for the virtual machine resource.')
param ImageVersion string = 'latest'

@description('IP addresses for the DNS servers.')
param IPAddresses array = [
  '10.0.1.4'
  '10.0.1.5'
]

@description('Location to deploy the Azure resources.')
param Location string = resourceGroup().location

@description('Name prefix for the NIC\'s on the virtual machines. A number will be added as a suffix based on the copy loop number.')
param NicNamePrefix string = 'nic-dns-p-eus-'

@description('The resource ID for the subnet of the DNS servers.')
param SubnetId string

@description('The timestamp is used to rerun VM extensions when the template needs to be redeployed due to an error or update.')
param Timestamp string = utcNow()

@description('Name prefix for the virtual machines.  A number will be added as a suffix based on the copy loop number.')
param VmNamePrefix string = 'vm-dns-p-eus-'

@description('The local administrator password for virtual machines.')
@secure()
param VmPassword string

@description('The size of the virtual machine.')
param VmSize string = 'Standard_D2s_v4'

@description('The local administrator username for virtual machines.')
param VmUsername string

var Netbios = split(DomainName, '.')[0]

resource AvSetName_resource 'Microsoft.Compute/availabilitySets@2019-07-01' = {
  name: AvSetName
  location: Location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    virtualMachines: []
  }
  dependsOn: []
}

resource NicNamePrefix_1 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, 2): {
  name: concat(NicNamePrefix, (i + 1))
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: IPAddresses[i]
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: SubnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
  dependsOn: []
}]

resource VmNamePrefix_1 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, 2): {
  name: concat(VmNamePrefix, (i + 1))
  location: Location
  properties: {
    availabilitySet: {
      id: AvSetName_resource.id
    }
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      imageReference: {
        publisher: ImagePublisher
        offer: ImageOffer
        sku: ImageSku
        version: ImageVersion
      }
      osDisk: {
        osType: 'Windows'
        name: concat(DiskNamePrefix, (i + 1))
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: DiskSku
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile: {
      computerName: concat(VmNamePrefix, (i + 1))
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
          id: resourceId('Microsoft.Network/networkInterfaces', concat(NicNamePrefix, (i + 1)))
        }
      ]
    }
    licenseType: ((HybridUseBenefit == 'yes') ? 'Windows_Server' : json('null'))
  }
  dependsOn: [
    NicNamePrefix_1
    AvSetName_resource
  ]
}]

resource VmNamePrefix_1_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, 2): {
  name: '${VmNamePrefix}${(i + 1)}/JsonADDomainExtension'
  location: Location
  properties: {
    forceUpdateTag: Timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: DomainName
      User: '${Netbios}\\${DomainUsername}'
      Restart: 'true'
      Options: '3'
    }
    protectedSettings: {
      Password: DomainPassword
    }
  }
  dependsOn: [
    concat(VmNamePrefix, (i + 1))
  ]
}]

resource VmNamePrefix_1_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, 2): {
  name: '${VmNamePrefix}${(i + 1)}/DSC'
  location: Location
  properties: {
    forceUpdateTag: Timestamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    settings: {
      modulesUrl: 'https://github.com/jamasten/Azure/raw/master/solutions/dnsForwarders/dsc/dnsForwarders.zip'
      configurationFunction: 'dnsForwarders.ps1\\dnsForwarders'
      configurationArguments: {
        ActionAfterReboot: 'ContinueConfiguration'
        ConfigurationMode: 'ApplyandAutoCorrect'
        RebootNodeIfNeeded: true
        IPAddresses: DnsForwarderIPAddress
      }
      properties: [
        {
          Name: 'IPAddresses'
          Value: DnsForwarderIPAddress
          TypeName: 'System.Array'
        }
      ]
    }
    protectedSettings: {}
  }
  dependsOn: [
    concat(VmNamePrefix, (i + 1))
    VmNamePrefix_1_JsonADDomainExtension
  ]
}]