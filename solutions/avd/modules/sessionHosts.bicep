param Availability string
param DiskSku string
param DodStigCompliance bool
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param EphemeralOsDisk string
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
param ManagedIdentityResourceId string
param NetworkSecurityGroupName string
param NetAppFileShare string
param OuPath string
param RdpShortPath bool
param ResourceNameSuffix string
param SecurityPrincipalId string
param SessionHostCount int
param SessionHostIndex int
param ScreenCaptureProtection bool
param StorageAccountName string
param StorageSolution string
param Subnet string
param Tags object
param Timestamp string
param UserAssignedIdentity string = ''
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
var Intune = DomainServices == 'NoneWithIntune' ? true : false
var LogAnalyticsWorkspaceResourceId = resourceId(HostPoolResourceGroupName, 'Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName)
var NvidiaVmSizes = [
  'Standard_NV6'
  'Standard_NV12'
  'Standard_NV24'
  'Standard_NV12s_v3'
  'Standard_NV24s_v3'
  'Standard_NV48s_v3'
  'Standard_NC4as_T4_v3'
  'Standard_NC8as_T4_v3'
  'Standard_NC16as_T4_v3'
  'Standard_NC64as_T4_v3'
]
var NvidiaVmSize = contains(NvidiaVmSizes, VmSize)
var PooledHostPool = (split(HostPoolType, ' ')[0] == 'Pooled')
var EphemeralOsDisk_var = {
  osType: 'Windows'
  createOption: 'FromImage'
  caching: 'ReadOnly'
  diffDiskSettings: {
    option: 'Local'
    placement: EphemeralOsDisk
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
var VmIdentityType = (contains(DomainServices, 'None') ? ((!empty(UserAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned') : ((!empty(UserAssignedIdentity)) ? 'UserAssigned' : 'None'))
var VmIdentityTypeProperty = {
  type: VmIdentityType
}
var VmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', UserAssignedIdentity)}': {}
  }
}
var VmIdentity = ((!empty(UserAssignedIdentity)) ? union(VmIdentityTypeProperty, VmUserAssignedIdentityProperty) : VmIdentityTypeProperty)


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'vmSizeValidation'
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
    arguments: '-Availability ${Availability} -DiskSku ${DiskSku} -ImageSku ${ImageSku} -Location ${Location} -VmSize ${VmSize}'
    scriptContent: '''
      param(
        [string]$Availability,
        [string]$DiskSku,
        [string]$ImageSku,
        [string]$Location,
        [string]$VmSize
      )
      $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq 'virtualMachines' -and $_.Name -eq $VmSize}
      # Availability Zones validation
      if($Availability -eq 'AvailabilityZones' -and $Sku.locationInfo.zones.count -lt 3){
        Write-Error -Exception 'Invalid Availability' -Message 'The selected VM Size does not support availability zones in this Azure location. https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-powershell-availability-zone' -ErrorAction Stop
      } elseif($Availability -eq 'AvailabilityZones' -and $Sku.locationInfo.zones.count -eq 3){
        $Zones = $true
      } else {
        $Zones = $false
      }
      # vCPU Validation: range = 4 min, 24 max
      $vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq 'vCPUs'}).value
      if($vCPUs -lt 4 -or $vCPUs -gt 24){
        Write-Error -Exception 'Invalid vCPU Count' -Message 'The selected VM Size does not contain the appropriate amount of vCPUs for Azure Virtual Desktop. https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs' -ErrorAction Stop
      }
      # Disk SKU validation
      if($DiskSku -like "Premium*" -and ($Sku.capabilities | Where-Object {$_.name -eq 'PremiumIO'}).value -eq $false){
        Write-Error -Exception 'Invalid Disk SKU' -Message 'The selected VM Size does not support the Premium SKU for managed disks.' -ErrorAction Stop
      }
      # Hyper-V Generation validation
      if($ImageSku -like "*-g2" -and ($Sku.capabilities | Where-Object {$_.name -eq 'HyperVGenerations'}).value -notlike "*2"){
        Write-Error -Exception 'Invalid Hyper-V Generation' -Message 'The VM size does not support the selected Image Sku.' -ErrorAction Stop
      }
      $DeploymentScriptOutputs = @{};
      $DeploymentScriptOutputs["acceleratedNetworking"] = ($Sku.capabilities | Where-Object {$_.name -eq 'AcceleratedNetworkingEnabled'}).value;
    '''
    timeout: 'PT2H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource roleAssignment_VmUserLogin 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = if (contains(DomainServices, 'None')) {
  name: guid(resourceGroup().id, 'VirtualMachineUserLogin')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
    principalId: SecurityPrincipalId
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = if (PooledHostPool && Availability == 'AvailabilitySet') {
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

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = if (RdpShortPath) {
  name: NetworkSecurityGroupName
  location: Location
  properties: {
    securityRules: [
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
    enableAcceleratedNetworking: deploymentScript.properties.outputs.acceleratedNetworking == 'True' ? true : false
    enableIPForwarding: false
    networkSecurityGroup: RdpShortPath ? {
      id: nsg.id
    } : null
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  zones: Availability == 'AvailabilityZones' ? [
    string((i % 3) + 1)
  ] : null
  identity: VmIdentity
  properties: {
    availabilitySet: Availability == 'AvailabilitySet' ? AvailabilitySetId : null
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
      osDisk: EphemeralOsDisk == 'None' ? StatefulOsDisk : EphemeralOsDisk_var
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
    vm
  ]
}]

resource jsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (contains(DomainServices, 'ActiveDirectory')) {
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
    vm
    microsoftMonitoringAgent
  ]
}]

resource aadLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (contains(DomainServices, 'None')) {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AADLoginForWindows'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: Intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : json('null')
  }
  dependsOn: [
    vm
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
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -AmdVmSize ${AmdVmSize} -DodStigCompliance ${DodStigCompliance} -DomainName ${DomainName} -Environment ${environment().name} -FSLogix ${FSLogix} -HostPoolName ${HostPoolName} -HostPoolRegistrationToken ${reference(resourceId(HostPoolResourceGroupName, 'Microsoft.DesktopVirtualization/hostpools', HostPoolName), '2019-12-10-preview').registrationInfo.token} -ImageOffer ${ImageOffer} -ImagePublisher ${ImagePublisher} -NetAppFileShare ${NetAppFileShare} -NvidiaVmSize ${NvidiaVmSize} -PooledHostPool ${PooledHostPool} -RdpShortPath ${RdpShortPath} -ScreenCaptureProtection ${ScreenCaptureProtection} -StorageAccountName ${StorageAccountName} -StorageSolution ${StorageSolution}'
    }
  }
  dependsOn: [
    vm
    jsonADDomainExtension
    aadLoginForWindows
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
    vm
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
    vm
    customScriptExtension
  ]
}]
