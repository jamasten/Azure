param FileShares array
param Location string
param PolicyId string
param ProtectionContainerName string
param SourceResourceId string
param Tags object


// Only configures backups for profile containers
// Office containers contain M365 cached data that does not need to be backed up
resource protectedItems_FileShare 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2022-03-01' = [for FileShare in FileShares: if(contains(FileShare, 'profile')) {
  name: '${ProtectionContainerName}/AzureFileShare;${FileShare}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    policyId: PolicyId
    sourceResourceId: SourceResourceId
  }
}]
