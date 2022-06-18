param DeploymentResourceGroup string
param KeyVaultName string
param Location string
//param ManagedIdentityName string
param ManagedIdentityPrincipalId string
param ManagedIdentityResourceId string
param NamingStandard string
@secure()
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

module deploymentScript 'deploymentScript.bicep' = {
  name: 'DeploymentScript_${Timestamp}'
  scope: resourceGroup(DeploymentResourceGroup)
  params: {
    KeyVaultName: vault.name
    Location: Location
    ManagedIdentityResourceId: ManagedIdentityResourceId
    NamingStandard: NamingStandard
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    Timestamp: Timestamp
  }
/* dependsOn: [
    roleAssignment
  ] */
}
