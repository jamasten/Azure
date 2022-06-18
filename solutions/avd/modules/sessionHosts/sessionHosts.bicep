param AcceleratedNetworking string
param AvailabilitySetCount int
param AvailabilitySetPrefix string
param AutomationAccountName string
param Availability string
param ConfigurationName string
param DisaStigCompliance bool
param DiskEncryption bool
param DiskSku string
param DivisionRemainderValue int
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param EphemeralOsDisk string
param FileShares array
param Fslogix bool
param HostPoolName string
param HostPoolType string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageVersion string
param KeyVaultName string
param Location string
param LogAnalyticsWorkspaceName string
param MaxResourcesPerTemplateDeployment int
param Monitoring bool
param NamingStandard string
param NetworkSecurityGroupName string
param NetAppFileShare string
param OuPath string
param PooledHostPool bool
param RdpShortPath bool
param ResourceGroups array
param RoleDefinitionIds object
param SasToken string
param ScreenCaptureProtection bool
param ScriptsUri string
param SecurityPrincipalObjectIds array
param SessionHostBatchCount int
param SessionHostIndex int
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSolution string
param StorageSuffix string
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


module availabilitySets 'availabilitySets.bicep' = if (PooledHostPool && Availability == 'AvailabilitySet') {
  name: 'AvailabilitySets_${Timestamp}'
  scope: resourceGroup(ResourceGroups[1]) // Hosts Resource Group
  params: {
    AvailabilitySetCount: AvailabilitySetCount
    AvailabilitySetPrefix: AvailabilitySetPrefix
    Location: Location
    Tags: Tags
  }
}

// Role Assignment for Virtual Machine Login User
// This module deploys the role assignments to login to Azure AD joined session hosts
module roleAssignments 'roleAssignments.bicep' = if (contains(DomainServices, 'None')) {
  name: 'RoleAssignments_${Timestamp}'
  scope: resourceGroup(ResourceGroups[1]) // Hosts Resource Group
  params: {
    RoleDefinitionId: RoleDefinitionIds.virtualMachineUserLogin
    SecurityPrincipalIds: SecurityPrincipalObjectIds
  }
}

module virtualMachines 'virtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'sessionHosts_${i-1}_${Timestamp}'
  scope: resourceGroup(ResourceGroups[1]) // Hosts Resource Group
  params: {
    AcceleratedNetworking: AcceleratedNetworking
    AutomationAccountName: AutomationAccountName
    Availability: Availability
    AvailabilitySetPrefix: AvailabilitySetPrefix
    ConfigurationName: ConfigurationName
    DisaStigCompliance: DisaStigCompliance
    DiskEncryption: DiskEncryption
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DomainServices: DomainServices
    EphemeralOsDisk: EphemeralOsDisk
    FileShares: FileShares
    Fslogix: Fslogix
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroups[2] // Management Resource Group
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    KeyVaultName: KeyVaultName
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    ManagementResourceGroup: ResourceGroups[2]
    Monitoring: Monitoring
    NamingStandard: NamingStandard
    NetworkSecurityGroupName: NetworkSecurityGroupName
    NetAppFileShare: NetAppFileShare
    OuPath: OuPath
    RdpShortPath: RdpShortPath
    ScreenCaptureProtection: ScreenCaptureProtection
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex 
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    VmPassword: VmPassword
    VmSize: VmSize
    VmUsername: VmUsername
  }
  dependsOn: [
    availabilitySets
  ]
}]