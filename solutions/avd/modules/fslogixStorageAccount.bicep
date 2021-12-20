@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainServices string
param HostPoolName string
param KerberosEncryptionType string
param Location string
param Netbios string
param OuPath string
param SecurityPrincipalId string
param SecurityPrincipalName string
param StorageAccountName string
param StorageSku string
param Tags object
param Timestamp string
param VmName string


var ResourceGroupName = resourceGroup().name
var RoleAssignmentName = guid(StorageAccountName, '0')
var RoleAssignmentName_Users = guid('${StorageAccountName}/default/${HostPoolName}', '0')
var VmNameFull = '${VmName}mgt'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: Location
  tags: Tags
  sku: {
    name: '${StorageSku}_LRS'
  }
  kind: StorageSku == 'Standard' ? 'StorageV2' : 'FileStorage'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: DomainServices == 'AzureActiveDirectory' ? 'AADDS' : 'None'
    }
    largeFileSharesState: StorageSku == 'Standard' ? 'Enabled' : 'Disabled'
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (DomainServices == 'ActiveDirectory') {
  scope: storageAccount
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(resourceId('Microsoft.Compute/virtualMachines', VmNameFull), '2020-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_Users 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: RoleAssignmentName_Users
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
    principalId: SecurityPrincipalId
  }
  dependsOn: [
    roleAssignment
  ]
}

resource storageAccount_FileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
  dependsOn: [
    roleAssignment
  ]
}

resource storageAccount_FileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  parent: storageAccount_FileServices
  name: toLower(HostPoolName)
  properties: {
    accessTier: StorageSku == 'Premium_LRS' ? 'Premium' : 'TransactionOptimized'
    shareQuota: 100
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    roleAssignment
  ]
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${VmNameFull}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/scripts/New-DomainJoinStorageAccount.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File New-DomainJoinStorageAccount.ps1 -DomainJoinPassword ${DomainJoinPassword} -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -DomainServices ${DomainServices} -Environment ${environment().name} -HostPoolName ${HostPoolName} -KerberosEncryptionType ${KerberosEncryptionType} -Netbios ${Netbios} -OuPath "${OuPath}" -ResourceGroupName ${ResourceGroupName} -SecurityPrincipalName "${SecurityPrincipalName}" -StorageAccountName ${StorageAccountName} -StorageKey ${listKeys(storageAccount.id, '2019-06-01').keys[0].value} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId}'
    }
  }
  dependsOn: [
    roleAssignment
    storageAccount_FileServices
    storageAccount_FileShare
  ]
}
