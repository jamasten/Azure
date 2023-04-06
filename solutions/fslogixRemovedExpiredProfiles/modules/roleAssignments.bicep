param AutomationAccountId string

var RoleDefinitionId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(AutomationAccountId, RoleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: AutomationAccountId
    principalType: 'ServicePrincipal'
  }
  dependsOn: []
}
