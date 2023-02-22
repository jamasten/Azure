param AutomationAccountId string
param RoleDefinitionId string


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(AutomationAccountId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: AutomationAccountId
    principalType: 'ServicePrincipal'
  }
  dependsOn: []
}
