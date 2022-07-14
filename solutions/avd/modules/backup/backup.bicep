param DivisionRemainderValue int
param FileShares array
param Fslogix bool
param Location string
param MaxResourcesPerTemplateDeployment int
param RecoveryServicesVaultName string
param SessionHostBatchCount int
param SessionHostIndex int
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageResourceGroupName string
param StorageSolution string
param Tags object
param Timestamp string
param TimeZone string
param VmName string
param VmResourceGroupName string


var BackupSchedulePolicy = {
  scheduleRunFrequency: 'Daily'
  scheduleRunTimes: [
    '23:00'
  ]
  schedulePolicyType: 'SimpleSchedulePolicy'
}
var BackupRetentionPolicy = {
  retentionPolicyType: 'LongTermRetentionPolicy'
  dailySchedule: {
    retentionTimes: [
      '23:00'
    ]
    retentionDuration: {
      count: 30
      durationType: 'Days'
    }
  }
}


resource vault 'Microsoft.RecoveryServices/vaults@2022-03-01' = {
  name: RecoveryServicesVaultName
  location: Location
  tags: Tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource backupPolicy_Storage 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' = if(Fslogix && StorageSolution == 'AzureStorageAccount') {
  parent: vault
  name: 'AvdPolicyStorage'
  location: Location
  tags: Tags
  properties: {
    backupManagementType: 'AzureStorage'
    schedulePolicy: BackupSchedulePolicy
    retentionPolicy: BackupRetentionPolicy
    timeZone: TimeZone
    workLoadType: 'AzureFileShare'
  }
}

resource backupPolicy_Vm 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-03-01' = if(!Fslogix) {
  parent: vault
  name: 'AvdPolicyVm'
  location: Location
  tags: Tags
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: BackupSchedulePolicy
    retentionPolicy: BackupRetentionPolicy
    timeZone: TimeZone
    instantRpRetentionRangeInDays: 2
  }
}

resource protectionContainers 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2022-03-01' = [for i in range(0, StorageCount): if(Fslogix && StorageSolution == 'AzureStorageAccount') {
  name: '${vault.name}/Azure/storagecontainer;Storage;${StorageResourceGroupName};${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: resourceId(StorageResourceGroupName, 'Microsoft.Storage/storageAccounts', '${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}')
  }
  dependsOn: [
    backupPolicy_Storage
  ]
}]

module protectedItems_FileShares 'backup_FileShares.bicep' = [for i in range(0, StorageCount): if(Fslogix && StorageSolution == 'AzureStorageAccount') {
  name: 'BackupProtectedItems_FileShares_${i + StorageIndex}_${Timestamp}'
  params: {
    FileShares: FileShares
    Location: Location
    ProtectionContainerName: protectionContainers[i].name
    PolicyId: backupPolicy_Storage.id
    SourceResourceId: resourceId(StorageResourceGroupName, 'Microsoft.Storage/storageAccounts', '${StorageAccountPrefix}${padLeft((i + StorageIndex), 2, '0')}')
    Tags: Tags
  }
}]

module protectedItems_Vm 'backup_VirtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): if(!Fslogix) {
  name: 'BackupProtectedItems_VirtualMachines_${i-1}_${Timestamp}'
  scope: resourceGroup(resourceGroup().name) // Management Resource Group
  params: {
    Location: Location
    PolicyId: backupPolicy_Vm.id
    RecoveryServicesVaultName: vault.name
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    Tags: Tags
    VmName: VmName
    VmResourceGroupName: VmResourceGroupName
  }
}]
