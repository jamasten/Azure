param HostPoolName string
param HostPoolResourceGroupName string
param Location string
param ManagedIdentityResourceId string
param NamingStandard string
param SasToken string
param ScriptsUri string
param Tags object
param Timestamp string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: 'ds-${NamingStandard}-drainMode'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityResourceId}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: Tags
  properties: {
    azPowerShellVersion: '5.4'
    cleanupPreference: 'OnSuccess'
    arguments: '-ResourceGroup ${HostPoolResourceGroupName} -HostPool ${HostPoolName}'
    primaryScriptUri: '${ScriptsUri}Set-AzureAvdDrainMode.ps1${SasToken}'
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
}
