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
var PooledHostPool = (split(HostPoolType, ' ')[0] == 'Pooled')

resource vault 'Microsoft.RecoveryServices/vaults@2016-06-01' = {
  name: RecoveryServicesVaultName
  location: Location
  tags: Tags
  sku: {
    name: 'RS0'
    //tier: 'Standard' // This property according to the language service isn't required, validate and remove
  }
  properties: {}
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2016-06-01' = {
  parent: vault
  name: 'AvdPolicy'
  location: Location
  tags: Tags
  properties: {
    backupManagementType: ((split(HostPoolType, ' ')[0] == 'Pooled') ? 'AzureStorage' : 'AzureIaasVM')
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '23:00'
      ]
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
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
    timeZone: TimeZone
    instantRpRetentionRangeInDays: ((split(HostPoolType, ' ')[0] == 'Pooled') ? null() : 2)
    workLoadType: ((split(HostPoolType, ' ')[0] == 'Pooled') ? 'AzureFileShare' : 'VM')
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
    vault
    backupPolicy
  ]
}

resource protectedItems 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2016-06-01' = if (PooledHostPool) {
  parent: protectionContainers
  name: 'AzureFileShare;${toLower(HostPoolName)}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    policyId: backupPolicy.id
    sourceResourceId: resourceId('Microsoft.Storage/storageAccounts', StorageAccountName)
    isInlineInquiry: 'true'
  }
}

resource RecoveryServicesVaultName_Azure_v2VmContainer_VmResourceGroupName_VmName_SessionHostIndex_3_0_v2Vm_VmResourceGroupName_VmName_SessionHostIndex_3_0 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2016-06-01' = [for i in range(0, SessionHostCount): if (!PooledHostPool) {
  name: '${vault.name}/Azure/${v2VmContainer}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/${v2Vm}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: backupPolicy.id
    sourceResourceId: resourceId(VmResourceGroupName, 'Microsoft.Compute/virtualMachines', '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}))
  }
}]
