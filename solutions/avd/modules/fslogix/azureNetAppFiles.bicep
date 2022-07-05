param ActiveDirectoryConnection string
param DelegatedSubnetId string
param DnsServers string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param FileShares array
param FslogixSolution string
param Location string
param ManagementVmName string
param NetAppAccountName string
param NetAppCapacityPoolName string
param OuPath string
param ResourceGroups array
param SasToken string
param ScriptsUri string
param SecurityPrincipalNames array
param SmbServerLocation string
param StorageSku string
param StorageSolution string
param Tags object
param Timestamp string


resource netAppAccount 'Microsoft.NetApp/netAppAccounts@2021-06-01' = {
  name: NetAppAccountName
  location: Location
  tags: Tags
  properties: {
    activeDirectories: ActiveDirectoryConnection == 'false' ? null : [
      {
        aesEncryption: false
        domain: DomainName
        dns: DnsServers
        organizationalUnit: OuPath
        password: DomainJoinPassword
        smbServerName: 'anf-${SmbServerLocation}'
        username: split(DomainJoinUserPrincipalName, '@')[0]
      }
    ]
    encryption: {
      keySource: 'Microsoft.NetApp'
    }
  }
}

resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2021-06-01' = {
  parent:netAppAccount
  name: NetAppCapacityPoolName
  location: Location
  tags: Tags
  properties: {
    coolAccess: false
    encryptionType: 'Single'
    qosType: 'Auto'
    serviceLevel: StorageSku
    size: 4398046511104
  }
}

resource volumes 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2021-06-01' = [for i in range(0, length(FileShares)): {
  parent: capacityPool
  name: FileShares[i]
  location: Location
  tags: Tags
  properties: {
    avsDataStore: 'Disabled'
    // backupId: 'string'
    coolAccess: false
    // coolnessPeriod: int
    creationToken: FileShares[i]
    // dataProtection: {
    //   backup: {
    //     backupEnabled: bool
    //     backupPolicyId: 'string'
    //     policyEnforced: bool
    //     vaultId: 'string'
    //   }
    //   replication: {
    //     endpointType: 'string'
    //     remoteVolumeRegion: 'string'
    //     remoteVolumeResourceId: 'string'
    //     replicationId: 'string'
    //     replicationSchedule: 'string'
    //   }
    //   snapshot: {
    //     snapshotPolicyId: 'string'
    //   }
    // }
    defaultGroupQuotaInKiBs: 0
    defaultUserQuotaInKiBs: 0
    encryptionKeySource: 'Microsoft.NetApp'
    // exportPolicy: {
    //   rules: [
    //     {
    //       allowedClients: 'string'
    //       chownMode: 'string'
    //       cifs: bool
    //       hasRootAccess: bool
    //       kerberos5iReadWrite: bool
    //       kerberos5pReadWrite: bool
    //       kerberos5ReadWrite: bool
    //       nfsv3: bool
    //       nfsv41: bool
    //       ruleIndex: int
    //       unixReadWrite: bool
    //     }
    //   ]
    // }
    isDefaultQuotaEnabled: false
    // isRestoring: bool
    kerberosEnabled: false
    ldapEnabled: false
    networkFeatures: 'Basic'
    protocolTypes: [ 
       'CIFS' 
    ]
    securityStyle: 'ntfs'
    serviceLevel: StorageSku
    // Enable when GA 
    //smbContinuouslyAvailable: true // recommended for FSLogix: https://docs.microsoft.com/en-us/azure/azure-netapp-files/enable-continuous-availability-existing-smb
    smbEncryption: true
    snapshotDirectoryVisible: true
    // snapshotId: 'string'
    subnetId: DelegatedSubnetId
    // throughputMibps: int
    // unixPermissions: 'string'
    usageThreshold: 107374182400
    // volumeType: 'string'
  }
}]

module ntfsPermissions 'ntfsPermissions.bicep' = {
  name: 'FslogixNtfsPermissions_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    CommandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-NetAppNtfsPermissions.ps1 -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -FslogixSolution ${FslogixSolution} -SecurityPrincipalNames "${SecurityPrincipalNames}" -SmbServerLocation ${SmbServerLocation} -StorageSolution ${StorageSolution}'
    Location: Location
    ManagementVmName: ManagementVmName
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    Tags: Tags
    Timestamp: Timestamp
  }
  dependsOn: [
    volumes
  ]
}

output fileShares array = contains(FslogixSolution, 'Office') ? [
  volumes[0].properties.mountTargets[0].smbServerFqdn
  volumes[1].properties.mountTargets[0].smbServerFqdn
] : [
  volumes[0].properties.mountTargets[0].smbServerFqdn
]
