param FileShares array
param FslogixShareSizeInGB int
param StorageAccountName string
param StorageSku string

resource shares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = [for i in range(0, length(FileShares)): {
  name: '${StorageAccountName}/default/${FileShares[i]}'
  properties: {
    accessTier: StorageSku == 'Premium' ? 'Premium' : 'TransactionOptimized'
    shareQuota: FslogixShareSizeInGB
    enabledProtocols: 'SMB'
  }
}]
