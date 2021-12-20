param HostPoolName string
param HostPoolType string
param Location string
param RecoveryServicesVaultName string
param SessionHostCount int
param SessionHostIndex int
param StorageAccountName string
param Tags object
param TimeZone string
param VmName string
param VmResourceGroupName string

var ResourceGroupName = resourceGroup().name
var FileShareBackupContainer = 'storagecontainer;Storage;${ResourceGroupName};${StorageAccountName}'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'
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

resource protectedItems_Vm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = [for i in range(0, SessionHostCount): if (!PooledHostPool) {
  name: '${vault.name}/Azure/${v2VmContainer}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/${v2Vm}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: backupPolicy_Vm.id
    sourceResourceId: resourceId(VmResourceGroupName, 'Microsoft.Compute/virtualMachines', '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}')
  }
}]
