param Availability string
param AvailabilitySetCount int
param AvailabilitySetNamePrefix string
param AvailabilityZones array
param DiskSku string
param DomainName string
param DomainServices string
param HostPoolName string
param HostPoolResourceGroupName string
param ImageId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageType string
param ImageVersion string
param KeyVaultName string
param KeyVaultResourceGroupName string
param KeyVaultSubscriptionId string
param Location string
param SessionHostCount int
param SessionHostIndex int
param SessionHostOuPath string
param SubnetResourceId string
param Timestamp string
param TrustedLaunch bool
param UserAssignedIdentity string = ''
param VirtualMachineNamePrefix string
param VirtualMachineSize string
param VirtualMachineTags object


var Intune = DomainServices == 'NoneWithIntune' ? true : false
var NetworkInterfaceNamePrefix = 'nic-${VirtualMachineNamePrefix}-'
var VmIdentityType = (contains(DomainServices, 'None') ? ((!empty(UserAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned') : ((!empty(UserAssignedIdentity)) ? 'UserAssigned' : 'None'))
var VmIdentityTypeProperty = {
  type: VmIdentityType
}
var VmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', UserAssignedIdentity)}': {}
  }
}
var VirtualMachineIdentity = ((!empty(UserAssignedIdentity)) ? union(VmIdentityTypeProperty, VmUserAssignedIdentityProperty) : VmIdentityTypeProperty)

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: KeyVaultName
  scope: resourceGroup(KeyVaultSubscriptionId, KeyVaultResourceGroupName)
}

module availabilitySets 'availabilitySets.bicep' = if (Availability == 'AvailabilitySet') {
  name: 'AvailabilitySets_${Timestamp}'
  params: {
    AvailabilitySetCount: AvailabilitySetCount
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    Location: Location
    Tags: VirtualMachineTags
  }
}

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, SessionHostCount): {
  name: '${NetworkInterfaceNamePrefix}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: VirtualMachineTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: SubnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}]

module virtualMachines 'virtualMachines.bicep' = {
  name: 'VirtualMachines_${Timestamp}'
  params: {
    Availability: Availability
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    AvailabilityZones: AvailabilityZones
    DiskSku: DiskSku
    ImageId  : ImageId
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageType: ImageType
    ImageVersion: ImageVersion
    Location: Location
    NetworkInterfaceNamePrefix: NetworkInterfaceNamePrefix
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    Tags: VirtualMachineTags
    TrustedLaunch: TrustedLaunch
    VirtualMachineIdentity: VirtualMachineIdentity
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
    VirtualMachinePassword: keyVault.getSecret('LocalAdminPassword')
    VirtualMachineSize: VirtualMachineSize
    VirtualMachineUsername: keyVault.getSecret('LocalAdminUsername')

  }
  dependsOn: [
    networkInterfaces
  ]
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 3, '0')}/CustomScriptExtension'
  location: Location
  tags: VirtualMachineTags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/mikedzikowski/AVDRipAndReplace/main/templateSpec/scripts/Set-SessionHostConfiguration.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -HostPoolRegistrationToken "${reference(resourceId(HostPoolResourceGroupName, 'Microsoft.DesktopVirtualization/hostpools', HostPoolName), '2019-12-10-preview').registrationInfo.token}"'
    }
  }
  dependsOn: [
    virtualMachines
  ]
}]

module jsonADDomainExtension 'extensionsJsonAdDomain.bicep' = if (contains(DomainServices, 'ActiveDirectory')) {
  name: 'JsonADDomainExtension_${Timestamp}'
  params: {
    DomainJoinPassword: keyVault.getSecret('DomainPassword')
    DomainJoinUserPrincipalName: keyVault.getSecret('DomainUserPrincipalName')
    DomainName: DomainName
    Location: Location
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    SessionHostOuPath: SessionHostOuPath
    Tags: VirtualMachineTags
    Timestamp: Timestamp
    VirtualMachineNamePrefix: VirtualMachineNamePrefix
  }
  dependsOn: [
    virtualMachines
    customScriptExtension
  ]
}

resource aadLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): if (contains(DomainServices, 'None')) {
  name: '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 3, '0')}/AADLoginForWindows'
  location: Location
  tags: VirtualMachineTags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: Intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : null
  }
  dependsOn: [
    virtualMachines
    customScriptExtension
  ]
}]
