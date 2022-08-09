param ConfigurationsUri string
param DnsServerForwarderIPAddresses array
param DnsServerSize string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param Environment string
param HybridUseBenefit bool
param Identifier string
param Location string
param LocationShortName string
param ManagedIdentityResourceId string
param NamingStandard string
param _artifactsLocationSasToken string
param ScriptsUri string
param StampIndexFull string
param StorageSuffix string
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string


var SubnetId = resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
var VmName = 'vm${Identifier}${Environment}${LocationShortName}${StampIndexFull}dns'


resource deploymentScript_GetDns 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-${NamingStandard}-getDns'
  location: Location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityResourceId}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-Subnet ${Subnet} -VirtualNetwork ${VirtualNetwork} -VirtualNetworkResourceGroup ${VirtualNetworkResourceGroup}'
    primaryScriptUri: '${ScriptsUri}Get-AzureVirtualNetworkDns.ps1${_artifactsLocationSasToken}'
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-${NamingStandard}-dns'
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: SubnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

module staticIpAddress 'staticIpAddress.bicep' = {
  name: 'staticIpAddress'
  params: {
    IpAddress: nic.properties.ipConfigurations[0].properties.privateIPAddress
    Location: Location
    NicName: nic.name
    SubnetId: SubnetId
    Tags: Tags
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: VmName
  location: Location
  tags: Tags
  properties: {
    hardwareProfile: {
      vmSize: DnsServerSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: 'disk-${NamingStandard}-dns'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS' // 99.9% SLA
        }
      }
    }
    osProfile: {
      computerName: VmName
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
        }
      ]
    }
    licenseType: HybridUseBenefit ? 'Windows_Server' : json('null')
  }
  dependsOn: [
    staticIpAddress
  ]
}

resource domainJoinExt 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vm.name}/JsonADDomainExtension'
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

resource dscExt 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: '${vm.name}/DSC'
  location: Location
  tags: Tags
  properties: {
    forceUpdateTag: Timestamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    settings: {
      modulesUrl: '${ConfigurationsUri}dnsForwarder.zip${_artifactsLocationSasToken}'
      configurationFunction: 'dnsForwarder.ps1\\dnsForwarder'
      configurationArguments: {
        ActionAfterReboot: 'ContinueConfiguration'
        ConfigurationMode: 'ApplyandAutoCorrect'
        RebootNodeIfNeeded: true
      }
      properties: [
        {
          Name: 'ForwarderIPAddresses'
          Value: DnsServerForwarderIPAddresses
          TypeName: 'System.Array'
        }
        {
          Name: 'StorageSuffix'
          Value: StorageSuffix
          TypeName: 'System.String'
        }
      ]
    }
    protectedSettings: {}
  }
  dependsOn: [
    domainJoinExt
  ]
}

resource deploymentScript_SetDns 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-${NamingStandard}-setDns'
  location: Location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityResourceId}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-Dns ${nic.properties.ipConfigurations[0].properties.privateIPAddress} -VirtualNetwork ${VirtualNetwork} -VirtualNetworkResourceGroup ${VirtualNetworkResourceGroup}'
    primaryScriptUri: '${ScriptsUri}Set-AzureVirtualNetworkDns.ps1${_artifactsLocationSasToken}'
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    dscExt
  ]
}
