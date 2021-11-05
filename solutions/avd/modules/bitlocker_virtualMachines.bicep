param KeyVaultUri string
param KeyEncryptionKeyUrl string
param KeyVaultResourceId string
param VmName string
param SessionHostIndex int
param Location string
param SessionHostCount int
param Timestamp string

resource sessionHostBitlockerExtensions 'Microsoft.Compute/virtualMachines/extensions@2017-03-30' = [for i in range(0, SessionHostCount): {
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
      KeyVaultURL: KeyVaultUri
      KeyVaultResourceId: KeyVaultResourceId
      KeyEncryptionKeyURL: KeyEncryptionKeyUrl
      KekVaultResourceId: KeyVaultResourceId
      KeyEncryptionAlgorithm: 'RSA-OAEP'
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}]
