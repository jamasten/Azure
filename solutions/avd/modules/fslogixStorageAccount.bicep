param ConfigurationsUri string
param DnsServerForwarderIPAddresses array
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
param Index int
param KerberosEncryption string
param Location string
param LocationShortName string
param ManagedIdentityResourceId string
param ManagementVmName string
param NamingStandard string
param PrivateDnsZoneName string
param PrivateEndpoint bool
param SasToken string
param ScriptsUri string
param SecurityPrincipalId string
param StampIndexFull string
param StorageAccountPrefix string
param StorageSku string
param StorageSuffix string
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string


var Endpoint = split(FslogixStorage, ' ')[2]
var ResourceGroupName = resourceGroup().name
var RoleAssignmentName_Users = guid('${StorageAccountName}/default/${HostPoolName}', '0')
var SmbMultiChannel = {
  multichannel: {
    enabled: true
  }
}
var SmbSettings = {
  versions: 'SMB3.0;SMB3.1.1;'
  authenticationMethods: 'NTLMv2;Kerberos;'
  kerberosTicketEncryption: KerberosEncryption == 'RC4' ? 'RC4-HMAC;' : 'AES-256;'
  channelEncryption: 'AES-128-CCM;AES-128-GCM;AES-256-GCM;'
}
var StorageAccountName = '${StorageAccountPrefix}${padLeft(Index, 2, '0')}'
var SubnetId = resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
var VirtualNetworkRules = {
  PrivateEndpoint: []
  PublicEndpoint: []
  ServiceEndpoint: [
    {
      id: SubnetId
      action: 'Allow'
    }
  ]
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: Location
  tags: Tags
  sku: {
    name: StorageSku == 'Standard' ? 'Standard_LRS' : 'Premium_LRS'
  }
  kind: StorageSku == 'Standard' ? 'StorageV2' : 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: VirtualNetworkRules[Endpoint]
      ipRules: []
      defaultAction: Endpoint == 'PublicEndpoint' ? 'Allow' : 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: DomainServices == 'AzureActiveDirectory' ? 'AADDS' : 'None'
    }
    largeFileSharesState: StorageSku == 'Standard' ? 'Enabled' : null
  }
}

resource roleAssignment_Vm 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: guid(StorageAccountName, 'Contributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: reference(resourceId('Microsoft.Compute/virtualMachines', ManagementVmName), '2020-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_Users 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: RoleAssignmentName_Users
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
    principalId: SecurityPrincipalId
  }
  dependsOn: [
    roleAssignment_Vm
  ]
}

resource storageAccount_FileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: StorageSku == 'Standard' ? SmbSettings : union(SmbSettings, SmbMultiChannel)
    }
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
  dependsOn: [
    roleAssignment_Vm
  ]
}

resource storageAccount_FileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = [for i in range(0, length(FileShares)): {
  parent: storageAccount_FileServices
  name: FileShares[i]
  properties: {
    accessTier: StorageSku == 'Premium' ? 'Premium' : 'TransactionOptimized'
    shareQuota: FslogixShareSizeInGB
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    roleAssignment_Users
  ]
}]

module privateEndpoint 'fslogixStorageAccount_PrivateEndpoint.bicep' = if(PrivateEndpoint) {
  name: 'fslogixStorageAccountd_PrivateEndpoint_${Timestamp}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    Location: Location
    PrivateDnsZoneName: PrivateDnsZoneName
    StorageAccountId: storageAccount.id
    StorageAccountName: storageAccount.name
    Subnet: Subnet
    Tags: Tags    
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
}

module dnsForwarder 'dnsForwarder.bicep' = if(PrivateEndpoint) {
  name: 'dnsForwarder_${Timestamp}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    ConfigurationsUri: ConfigurationsUri
    DnsServerForwarderIPAddresses: DnsServerForwarderIPAddresses
    DnsServerSize: DnsServerSize
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    Environment: Environment
    HybridUseBenefit: HybridUseBenefit
    Identifier: Identifier
    Location: Location
    LocationShortName: LocationShortName
    ManagedIdentityResourceId: ManagedIdentityResourceId
    NamingStandard: NamingStandard
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    StampIndexFull: StampIndexFull
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
}
