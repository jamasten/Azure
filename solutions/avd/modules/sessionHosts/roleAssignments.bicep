param RoleDefinitionId string
param SecurityPrincipalIds array


resource roleAssignments 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = [for i in range(0, length(SecurityPrincipalIds)): {
  name: guid(string(i), RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: SecurityPrincipalIds[i]
  }
}]
