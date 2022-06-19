param ActiveDirectoryConnection string
param DelegatedSubnetId string
param DnsServers string
@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param HostPoolName string
param Location string
param ManagementVmName string
param NetAppAccountName string
param NetAppCapacityPoolName string
param OuPath string
param NamingStandard string
param SasToken string
param ScriptsUri string
param SecurityPrincipalNames array
param SmbServerLocation string
param StorageSku string
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

resource volume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2021-06-01' = {
  parent: capacityPool
  name: HostPoolName
  location: Location
  tags: Tags
  properties: {
    avsDataStore: 'Disabled'
    // backupId: 'string'
    coolAccess: false
    // coolnessPeriod: int
    creationToken: HostPoolName
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
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${ManagementVmName}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptsUri}Set-NetAppNtfsPermissions.ps1${SasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-NetAppNtfsPermissions.ps1 -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -HostPoolName ${HostPoolName} -NamingStandard ${NamingStandard} -SecurityPrincipalNames "${SecurityPrincipalNames}" -SmbServerLocation ${SmbServerLocation}'
    }
  }
  dependsOn: [
    volume
  ]
}

output fileShare string = volume.properties.mountTargets[0].smbServerFqdn
