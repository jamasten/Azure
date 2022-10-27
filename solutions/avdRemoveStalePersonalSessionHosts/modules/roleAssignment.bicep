param RoleDefinitionId string
param PrincipalId string

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(PrincipalId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}
