param AutomationAccountId string


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(AutomationAccountId, 'ScalingContributor', resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: AutomationAccountId
    principalType: 'ServicePrincipal'
  }
  dependsOn: []
}
