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
param FslogixSolution string
param FslogixStorage string
param HybridUseBenefit bool
param Identifier string
param KerberosEncryption string
param Location string
param LocationShortName string
param ManagedIdentityResourceId string
param ManagementVmName string
param NamingStandard string
param Netbios string
param OuPath string
param PrivateDnsZoneName string
param PrivateEndpoint bool
param ResourceGroups array
param RoleDefinitionIds object
param SasToken string
param ScriptsUri string
param SecurityPrincipalIds array
param SecurityPrincipalNames array
param StampIndexFull string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageSku string
param StorageSolution string
param StorageSuffix string
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
@secure()
param VmPassword string
param VmUsername string


var DeploymentResourceGroup = ResourceGroups[0]
var Endpoint = split(FslogixStorage, ' ')[2]
var ResourceGroupName = resourceGroup().name
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


resource storageAccounts 'Microsoft.Storage/storageAccounts@2021-02-01' = [for i in range(StorageIndex, StorageCount): {
  name: '${StorageAccountPrefix}${padLeft(i, 2, '0')}'
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
}]

// Assigns the Mgmt VM's managed identity to the storage account
// This is needed so the custom script extension can domain join the storage account, change the Kerberos encryption if needed, and update the NTFS permissions
resource roleAssignment_Vm 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for i in range(StorageIndex, StorageCount): {
  scope: storageAccounts[i]
  name: guid(storageAccounts[i].name, RoleDefinitionIds.contributor, ManagementVmName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.contributor)
    principalId: reference(resourceId(DeploymentResourceGroup, 'Microsoft.Compute/virtualMachines', ManagementVmName), '2020-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}]

// Assigns the SMB Contributor role to the Storage Account so users can save their profiles to the file share using FSLogix
resource roleAssignment_Users 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [for i in range(StorageIndex, StorageCount): {
  scope: storageAccounts[i]
  name: guid(SecurityPrincipalIds[i], RoleDefinitionIds.storageFileDataSMBShareContributor, storageAccounts[i].name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.storageFileDataSMBShareContributor)
    principalId: SecurityPrincipalIds[i]
  }
  dependsOn: [
    roleAssignment_Vm
  ]
}]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = [for i in range(StorageIndex, StorageCount): {
  parent: storageAccounts[i]
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
}]

module shares 'shares.bicep' = [for i in range(StorageIndex, StorageCount): {
  name: 'FileShares_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroups[3]) // Storage Resource Group
  params: {
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    StorageAccountName: '${StorageAccountPrefix}${padLeft(i, 2, '0')}'
    StorageSku: StorageSku
  }
  dependsOn: [
    roleAssignment_Users
  ]
}]

module privateEndpoint 'privateEndpoint.bicep' = [for i in range(StorageIndex, StorageCount): if(PrivateEndpoint) {
  name: 'PrivateEndpoints_${i}_${Timestamp}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    Location: Location
    PrivateDnsZoneName: PrivateDnsZoneName
    StorageAccountId: storageAccounts[i].id
    StorageAccountName: storageAccounts[i].name
    Subnet: Subnet
    Tags: Tags    
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
}]

module dnsForwarder 'dnsForwarder.bicep' = if(PrivateEndpoint) {
  name: 'DnsForwarder_${Timestamp}'
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

module ntfsPermissions '../ntfsPermissions.bicep' = if(!contains(DomainServices, 'None')) {
  name: 'FslogixNtfsPermissions_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    CommandToExecute: 'powershell -ExecutionPolicy Unrestricted -File New-DomainJoinStorageAccount.ps1 -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -DomainServices ${DomainServices} -Environment ${environment().name} -FslogixSolution ${FslogixSolution} -KerberosEncryptionType ${KerberosEncryption} -Netbios ${Netbios} -OuPath "${OuPath}" -SecurityPrincipalNames "${SecurityPrincipalNames}" -StorageAccountPrefix ${StorageAccountPrefix} -StorageAccountResourceGroupName ${ResourceGroups[3]} -StorageCount ${StorageCount} -StorageIndex ${StorageIndex} -StorageSolution ${StorageSolution} -StorageSuffix ${environment().suffixes.storage} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId}'
    Location: Location
    ManagementVmName: ManagementVmName
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    Tags: Tags
    Timestamp: Timestamp
  }
  dependsOn: [
    shares
    privateEndpoint
    dnsForwarder
  ]
}
