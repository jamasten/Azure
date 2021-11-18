param DiskSku string
param DodStigCompliance bool
param DomainName string

@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param EphemeralOsDisk bool
param FSLogix bool
param HostPoolName string
param HostPoolResourceGroupName string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageVersion string
param Location string
param LogAnalyticsWorkspaceName string
param NetworkSecurityGroupName string
param OuPath string
param RdpShortPath bool
param ResourceNameSuffix string
param SessionHostCount int
param SessionHostIndex int
param ScreenCaptureProtection bool
param StorageAccountName string
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string

@secure()
param VmPassword string
param VmSize string
param VmUsername string

var AmdVmSizes = [
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
]
var AmdVmSize = contains(AmdVmSizes, VmSize)
var AvailabilitySetName = 'as-${ResourceNameSuffix}'
var AvailabilitySetId = {
  id: resourceId('Microsoft.Compute/availabilitySets', AvailabilitySetName)
}
var LogAnalyticsWorkspaceResourceId = resourceId(HostPoolResourceGroupName, LogAnalyticsWorkspaceName)
var NvidiaVmSizes = [
  'Standard_NV6'
  'Standard_NV12'
  'Standard_NV24'
  'Standard_NV12s_v3'
  'Standard_NV24s_v3'
  'Standard_NV48s_v3'
]
var NvidiaVmSize = contains(NvidiaVmSizes, VmSize)
var PooledHostPool = (split(HostPoolType, ' ')[0] == 'Pooled')
var EphemeralOsDisk_var = {
  osType: 'Windows'
  createOption: 'FromImage'
  caching: 'ReadOnly'
  diffDiskSettings: {
    option: 'Local'
  }
}
var StatefulOsDisk = {
  osType: 'Windows'
  createOption: 'FromImage'
  caching: 'None'
  managedDisk: {
    storageAccountType: DiskSku
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = if (PooledHostPool) {
  name: AvailabilitySetName
  location: Location
  tags: Tags
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = if(RdpShortPath) {
  name: NetworkSecurityGroupName
  location: Location
  properties: {
    securityRules:[
      {
        name: 'AllowRdpShortPath'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '3390'
          direction: 'Inbound'
          priority: 3390
          protocol: 'Udp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, SessionHostCount): {
  name: 'nic-${ResourceNameSuffix}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(subscription().subscriptionId, VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: RdpShortPath ? json(concat('{"id": "', nsg.id, '"}')) : null 
  }
}]

resource sessionHosts 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    availabilitySet: PooledHostPool ? AvailabilitySetId : null
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
      osDisk: (EphemeralOsDisk ? EphemeralOsDisk_var : StatefulOsDisk)
      dataDisks: []
    }
    osProfile: {
      computerName: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
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
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic-${ResourceNameSuffix}${padLeft((i + SessionHostIndex), 3, '0')}')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: ((ImagePublisher == 'MicrosoftWindowsServer') ? 'Windows_Server' : 'Windows_Client')
  }
  dependsOn: [
    availabilitySet
    nic
  ]
}]

resource microsoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/MicrosoftMonitoringAgent'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(LogAnalyticsWorkspaceResourceId, '2015-03-20').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(LogAnalyticsWorkspaceResourceId, '2015-03-20').primarySharedKey
    }
  }
  dependsOn: [
    sessionHosts
  ]
}]

resource jsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/JsonADDomainExtension'
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
      OUPath: OuPath
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
  dependsOn: [
    sessionHosts
    microsoftMonitoringAgent
  ]
}]

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/scripts/Set-SessionHostConfiguration.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -AmdVmSize ${AmdVmSize} -DodStigCompliance ${DodStigCompliance} -Environment ${environment().name} -FSLogix ${FSLogix} -HostPoolName ${HostPoolName} -HostPoolRegistrationToken ${reference(resourceId(HostPoolResourceGroupName, 'Microsoft.DesktopVirtualization/hostpools', HostPoolName), '2019-12-10-preview').registrationInfo.token} -ImageOffer ${ImageOffer} -ImagePublisher ${ImagePublisher} -NvidiaVmSize ${NvidiaVmSize} -PooledHostPool ${PooledHostPool} -ScreenCaptureProtection ${ScreenCaptureProtection} -StorageAccountName ${StorageAccountName}'
    }
  }
  dependsOn: [
    sessionHosts
    jsonADDomainExtension
  ]
}]

resource amdGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (AmdVmSize) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AmdGpuDriverWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'AmdGpuDriverWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    sessionHosts
    customScriptExtension
  ]
}]

resource nvidiaGpuDriverWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (NvidiaVmSize) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/NvidiaGpuDriverWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.2'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    sessionHosts
    customScriptExtension
  ]
}]
