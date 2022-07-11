param FileShares array
param Location string
param PolicyId string
param ProtectionContainerName string
param SourceResourceId string
param Tags object


resource protectedItems_FileShares 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2022-03-01' = [for FileShare in FileShares: {
  name: '${ProtectionContainerName}/AzureFileShare;${FileShare}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    policyId: PolicyId
    sourceResourceId: SourceResourceId
  }
}]
