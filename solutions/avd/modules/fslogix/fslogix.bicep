targetScope = 'subscription'


param ActiveDirectoryConnection string
param ConfigurationsUri string
param DelegatedSubnetId string
param DiskEncryption bool
param DnsServerForwarderIPAddresses array
param DnsServers string
param DnsServerSize string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param Environment string
param FileShares array
param FslogixShareSizeInGB int
param FslogixStorage string
param HostPoolName string
param HybridUseBenefit bool
param Identifier string
param KerberosEncryption string
param KeyVaultName string
param Location string
param LocationShortName string
param ManagedIdentityResourceId string
param ManagementVmName string
param NamingStandard string
param NetAppAccountName string
param NetAppCapacityPoolName string
param Netbios string
param OuPath string
param PrivateDnsZoneName string
param PrivateEndpoint bool
param SasToken string
param ScriptsUri string
param SecurityPrincipalIds array 
param SecurityPrincipalNames array
param SmbServerLocation string
param StampIndexFull string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSku string
param StorageSolution string
param StorageSuffix string
param Subnet string
param ResourceGroups array
param RoleDefinitionIds object
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string


// Fslogix Management VM
// This module is required to fully configure any storage option for FSLogix
module managementVirtualMachine 'managementVirtualMachine.bicep' = if(!contains(DomainServices, 'None')) {
  name: 'ManagementVirtualMachine_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    DiskEncryption: DiskEncryption
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    KeyVaultName: KeyVaultName
    Location: Location
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    ResourceGroups: ResourceGroups
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmPassword: VmPassword
    VmUsername: VmUsername
  }

}

// Azure NetApp Files for Fslogix
module azureNetAppFiles 'azureNetAppFiles.bicep' = if(StorageSolution == 'AzureNetAppFiles' && !contains(DomainServices, 'None')) {
  name: 'AzureNetAppFiles_${Timestamp}'
  scope: resourceGroup(ResourceGroups[3]) // Storage Resource Group
  params: {
    ActiveDirectoryConnection: ActiveDirectoryConnection
    DelegatedSubnetId: DelegatedSubnetId
    DnsServers: DnsServers
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    HostPoolName: HostPoolName
    Location: Location
    ManagementVmName: ManagementVmName
    NetAppAccountName: NetAppAccountName
    NetAppCapacityPoolName: NetAppCapacityPoolName
    OuPath: OuPath
    NamingStandard: NamingStandard
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    SecurityPrincipalNames: SecurityPrincipalNames
    SmbServerLocation: SmbServerLocation
    StorageSku: StorageSku
    Tags: Tags
    Timestamp: Timestamp
  }
  dependsOn: [
    managementVirtualMachine
  ]
}

// Azure Files for FSLogix
module azureFiles 'azureFiles/azureFiles.bicep' = if(StorageSolution == 'AzureStorageAccount' && !contains(DomainServices, 'None')) {
  name: 'AzureFiles_${Timestamp}'
  scope: resourceGroup(ResourceGroups[3]) // Storage Resource Group
  params: {
    ConfigurationsUri: ConfigurationsUri
    DnsServerForwarderIPAddresses: DnsServerForwarderIPAddresses
    DnsServerSize: DnsServerSize
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DomainServices: DomainServices
    Environment: Environment
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    FslogixStorage: FslogixStorage
    HybridUseBenefit: HybridUseBenefit
    Identifier: Identifier
    KerberosEncryption: KerberosEncryption
    Location: Location
    LocationShortName: LocationShortName
    ManagedIdentityResourceId: ManagedIdentityResourceId
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    Netbios: Netbios
    OuPath: OuPath
    PrivateDnsZoneName: PrivateDnsZoneName
    PrivateEndpoint: PrivateEndpoint
    ResourceGroups: ResourceGroups
    RoleDefinitionIds: RoleDefinitionIds
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    SecurityPrincipalIds: SecurityPrincipalIds
    SecurityPrincipalNames: SecurityPrincipalNames
    StampIndexFull: StampIndexFull
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSku: StorageSku
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
  dependsOn: [
    managementVirtualMachine
  ]
}

output netAppShare string = azureNetAppFiles.outputs.fileShare
