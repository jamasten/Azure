param FSLogix bool
param KeyVaultName string
param Location string
param SessionHostCount int
param SessionHostIndex int
param SessionHostResourceGroupName string
param Timestamp string
param VmName string

var ManagedIdentityName = 'uami-bitlocker-kek'
var RoleAssignmentName = guid(resourceGroup().id, ManagedIdentityName)

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(uami.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}

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
        objectId: reference(uami.id, '2018-11-30', 'Full').properties.principalId
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
      '${uami.id}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: {}
  properties: {
    azPowerShellVersion: '5.4'
    cleanupPreference: 'OnSuccess'
    scriptContent: 'param([string][Parameter(Mandatory=$true)]$KeyVault);if(!(Get-AzKeyVaultKey -Name DiskEncryption -VaultName $KeyVault)){Add-AzKeyVaultKey -Name DiskEncryption -VaultName $KeyVault -Destination Software};$KeyEncryptionKeyURL = (Get-AzKeyVaultKey -VaultName $KeyVault -Name DiskEncryption -IncludeVersions | Where-Object {$_.Enabled -eq $true}).Id;Write-Output $KeyEncryptionKeyURL;$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs[\'text\'] = $KeyEncryptionKeyURL'
    arguments: ' -KeyVault ${vault.name}'
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
  dependsOn: [
    roleAssignment
  ]
}

resource mgmtBitlockerExtension 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = if (FSLogix) {
  name: '${VmName}mgt/AzureDiskEncryption'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: vault.properties.vaultUri
      KeyVaultResourceId: vault.id
      KeyEncryptionKeyURL: deploymentScript.properties.outputs.text
      KekVaultResourceId: vault.id
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}

module sessionHostBitlockerExtensionsDeployment './bitlocker_virtualMachines.bicep' = {
  name: 'DeployDiskEncryptionExtension'
  scope: resourceGroup(SessionHostResourceGroupName)
  params: {
    KeyVaultUri: vault.properties.vaultUri
    KeyEncryptionKeyUrl: deploymentScript.properties.outputs.text
    KeyVaultResourceId: vault.id
    VmName: VmName
    SessionHostIndex: SessionHostIndex
    Location: Location
    SessionHostCount: SessionHostCount
    Timestamp: Timestamp
  }
}
