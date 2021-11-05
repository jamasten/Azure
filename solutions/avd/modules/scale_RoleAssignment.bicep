param AutomationAccountName string
param AutomationAccountResourceGroupName string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-09-01-preview' = {
  name: guid(resourceGroup().id, 'ScalingContributor')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(resourceId(AutomationAccountResourceGroupName, 'Microsoft.Automation/automationAccounts', AutomationAccountName), '2020-01-13-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: []
}
