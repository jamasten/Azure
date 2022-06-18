param Availability string
param DiskEncryption bool
param DiskSku string
param DomainName string
param DomainServices string
param EphemeralOsDisk bool
param FSLogixStorage string
param ImageSku string
param KerberosEncryption string
param Location string
param ManagedIdentityResourceId string
param NamingStandard string
param SasToken string
param ScriptsUri string
param SecurityPrincipalIds array
param SecurityPrincipalNames array
param SessionHostCount int
param SessionHostIndex int
param StartVmOnConnect bool
param StorageCount int
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmSize string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-${NamingStandard}-validation'
  location: Location
  tags: Tags
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
    arguments: '-Availability ${Availability} -DiskEncryption ${DiskEncryption} -DiskSku ${DiskSku} -DomainName ${DomainName} -DomainServices ${DomainServices} -EphemeralOsDisk ${EphemeralOsDisk} -FSLogixStorage \\"${FSLogixStorage}\\" -ImageSku ${ImageSku} -KerberosEncryption ${KerberosEncryption} -Location ${Location} -SecurityPrincipalIds ${SecurityPrincipalIds} -SecurityPrincipalNames ${SecurityPrincipalNames} -SessionHostCount ${SessionHostCount} -SessionHostIndex ${SessionHostIndex} -StartVmOnConnect ${StartVmOnConnect} -StorageCount ${StorageCount} -VmSize ${VmSize} -VnetName ${VirtualNetwork} -VnetResourceGroupName ${VirtualNetworkResourceGroup}'
    primaryScriptUri: '${ScriptsUri}Get-Validation.ps1${SasToken}'
    timeout: 'PT2H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output acceleratedNetworking string = deploymentScript.properties.outputs.acceleratedNetworking
output anfActiveDirectory string = deploymentScript.properties.outputs.anfActiveDirectory
output avdObjectId string = deploymentScript.properties.outputs.avdObjectId
output dnsServers string = deploymentScript.properties.outputs.dnsServers
output ephemeralOsDisk string = deploymentScript.properties.outputs.ephemeralOsDisk
output sessionHostBatches array = deploymentScript.properties.outputs.sessionHostBatches
output sessionHostIndexes array = deploymentScript.properties.outputs.sessionHostIndexes
output subnetId string = deploymentScript.properties.outputs.subnetId
