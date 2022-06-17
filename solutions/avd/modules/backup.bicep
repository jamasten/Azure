param DivisionRemainderValue int
param HostPoolName string
param HostPoolType string
param Location string
param MaxResourcesPerTemplateDeployment int
param RecoveryServicesVaultName string
param SessionHostBatchCount int
param SessionHostIndex int
param StorageAccountName string
param Tags object
param Timestamp string
param TimeZone string
param VmName string
param VmResourceGroupName string

var ResourceGroupName = resourceGroup().name
var FileShareBackupContainer = 'storagecontainer;Storage;${ResourceGroupName};${StorageAccountName}'
var PooledHostPool = split(HostPoolType, ' ')[0] == 'Pooled'
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

resource vault 'Microsoft.RecoveryServices/vaults@2016-06-01' = {
  name: RecoveryServicesVaultName
  location: Location
  tags: Tags
  sku: {
    name: 'RS0'
  }
  properties: {}
}

resource backupPolicy_Storage 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-08-01' = if(PooledHostPool) {
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

resource backupPolicy_Vm 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-08-01' = if(!(PooledHostPool)) {
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

resource protectionContainers 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2016-12-01' = if (PooledHostPool) {
  name: '${vault.name}/Azure/${FileShareBackupContainer}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: resourceId('Microsoft.Storage/storageAccounts', StorageAccountName)
  }
  dependsOn: [
    backupPolicy_Storage
  ]
}

resource protectedItems_FileShare 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = if (PooledHostPool) {
  parent: protectionContainers
  name: 'AzureFileShare;${toLower(HostPoolName)}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    policyId: backupPolicy_Storage.id
    sourceResourceId: resourceId('Microsoft.Storage/storageAccounts', StorageAccountName)
  }
}

module protectedItems_Vm 'backup_VirtualMachines.bicep' = [for i in range(1, SessionHostBatchCount): if (!PooledHostPool) {
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
