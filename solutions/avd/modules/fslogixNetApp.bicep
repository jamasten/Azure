@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param HostPoolName string
param Location string
param ManagedIdentityName string
param NetAppAccountName string
param NetAppCapacityPoolName string
param OuPath string
param ResourceNameSuffix string
param SecurityPrincipalName string
param StorageSku string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string

var VmNameFull = '${VmName}mgt'

resource info 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'Info'
  location: Location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', ManagedIdentityName)}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-Location ${Location} -ResourceGroup ${VirtualNetworkResourceGroup} -VnetName ${VirtualNetwork}'
    scriptContent: 'param([string]$ResourceGroup, [string]$VnetName); $vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroup; $dnsServers = "$($vnet.DhcpOptions.DnsServers[0]),$($vnet.DhcpOptions.DnsServers[1])"; $subnetId = ($vnet.Subnets | Where-Object {$_.Delegations[0].ServiceName -eq "Microsoft.NetApp/volumes"}).Id; Install-Module -Name "Az.NetAppFiles" -Force; $DeployAnfAd = "true"; $Accounts = Get-AzResource -ResourceType "Microsoft.NetApp/netAppAccounts" | Where-Object {$_.Location -eq $Location}; foreach($Account in $Accounts){$AD = Get-AzNetAppFilesActiveDirectory -ResourceGroupName $Account.ResourceGroupName -AccountName $Account.Name; if($AD.ActiveDirectoryId){$DeployAnfAd = "false"}}; $DeploymentScriptOutputs = @{}; $DeploymentScriptOutputs["dnsServers"] = $dnsServers; $DeploymentScriptOutputs["subnetId"] = $subnetId; $DeploymentScriptOutputs["anfAd"] = $DeployAnfAd;'
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource netApp_Account 'Microsoft.NetApp/netAppAccounts@2021-06-01' = {
  name: NetAppAccountName
  location: Location
  tags: Tags
  properties: {
    activeDirectories: reference(info.name).outputs.anfAd == 'false' ? null : [
      {
        aesEncryption: false
        domain: DomainName
        dns: reference(info.name).outputs.dnsServers
        organizationalUnit: OuPath
        password: DomainJoinPassword
        smbServerName: ResourceNameSuffix
        username: split(DomainJoinUserPrincipalName, '@')[0]
      }
    ]
    encryption: {
      keySource: 'Microsoft.NetApp'
    }
  }
}

resource netApp_CapacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2021-06-01' = {
  parent:netApp_Account
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

resource netApp_Volume 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2021-06-01' = {
  parent: netApp_CapacityPool
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
    subnetId: reference(info.name).outputs.subnetId
    // throughputMibps: int
    // unixPermissions: 'string'
    usageThreshold: 107374182400
    // volumeType: 'string'
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${VmNameFull}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/scripts/Set-NetAppNtfsPermissions.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-NetAppNtfsPermissions.ps1 -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -HostPoolName ${HostPoolName} -ResourceNameSuffix ${ResourceNameSuffix} -SecurityPrincipalName "${SecurityPrincipalName}"'
    }
  }
  dependsOn: [
    netApp_Volume
  ]
}

output fileshare string = netApp_Volume.properties.mountTargets[0].smbServerFqdn
