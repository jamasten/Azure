param Condition bool
param PrincipalId string
param RoleDefinitionId string


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(Condition) {
  name: guid(PrincipalId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}
