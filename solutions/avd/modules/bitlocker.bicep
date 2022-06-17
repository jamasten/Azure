param KeyVaultName string
param Location string
//param ManagedIdentityName string
param ManagedIdentityPrincipalId string
param ManagedIdentityResourceId string
param SasToken string
param ScriptsUri string
param Timestamp string


/* resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ManagedIdentityName, 'Contributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: ManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
} */

resource vault 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: KeyVaultName
  location: Location
  tags: {}
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: ManagedIdentityPrincipalId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
          ]
          secrets: []
        }
      }
    ]
    enabledForDeployment: false
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: true
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: 'ds-bitlocker-kek'
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
    primaryScriptUri: '${ScriptsUri}New-AzureKeyEncryptionKey.ps1${SasToken}'
    arguments: ' -KeyVault ${vault.name}'
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
/*   dependsOn: [
    roleAssignment
  ] */
}
