param RoleDefinitionId string
param SecurityPrincipalIds array


resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(SecurityPrincipalIds)): {
  name: guid(string(i), RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: SecurityPrincipalIds[i]
  }
}]
