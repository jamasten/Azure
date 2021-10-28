param reference_parameters_KeyVaultName_vaultUri object
param reference_ds_bitlocker_kek_outputs_text object
param resourceId_Microsoft_KeyVault_vaults_parameters_KeyVaultName string
param VmName string
param SessionHostIndex int
param Location string
param SessionHostCount int
param Timestamp string

resource VmName_SessionHostIndex_3_0_AzureDiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/AzureDiskEncryption'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: reference_parameters_KeyVaultName_vaultUri.vaultUri
      KeyVaultResourceId: resourceId_Microsoft_KeyVault_vaults_parameters_KeyVaultName
      KeyEncryptionKeyURL: reference_ds_bitlocker_kek_outputs_text.outputs.text
      KekVaultResourceId: resourceId_Microsoft_KeyVault_vaults_parameters_KeyVaultName
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}]