param Environment string
param Location string
param LocationShortName string
param StorageUri string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-aib-${Environment}-${LocationShortName}'
  location: Location
  tags: Tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-SubnetName ${SubnetName} -VirtualNetworkName ${VirtualNetworkName} -VirtualNetworkResourceGroupName ${VirtualNetworkResourceGroupName}'
    primaryScriptUri: '${StorageUri}Disable-AzurePrivateLinkServiceNetworkPolicy.ps1'
    timeout: 'PT2H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
