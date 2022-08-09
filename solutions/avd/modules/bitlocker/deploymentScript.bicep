param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param KeyVaultName string
param Location string
param ManagedIdentityResourceId string
param NamingStandard string
param Timestamp string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: 'ds-${NamingStandard}-bitlockerKek'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityResourceId}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: {}
  properties: {
    azPowerShellVersion: '5.4'
    cleanupPreference: 'OnSuccess'
    primaryScriptUri: '${_artifactsLocation}New-AzureKeyEncryptionKey.ps1${_artifactsLocationSasToken}'
    arguments: ' -KeyVault ${KeyVaultName}'
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
}
