param KeyVault string
param StorageAccount string
param StorageAccountResourceGroup string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: StorageAccount
  scope: resourceGroup(StorageAccountResourceGroup)
}

resource keyVault 'Microsoft.KeyVault/vaults@2016-10-01' existing = {
  name: KeyVault
}

resource secret_VmPassword 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVault
  name: StorageAccount
  properties: {
    value: listKeys(storageAccount.id, '2021-02-01').keys[0].value
  }
}
