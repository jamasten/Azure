param PrincipalId string
param RoleDefinitionId string
param StorageAccountName string = ''


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = if(!(empty(StorageAccountName))) {
  name: StorageAccountName
}

resource roleAssignment_stg 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if(!(empty(StorageAccountName))) {
  name: guid(PrincipalId, RoleDefinitionId, resourceGroup().id)
  scope: storageAccount
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_rg 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(empty(StorageAccountName)) {
  name: guid(PrincipalId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}
