param ManagedIdentityId string
param NetworkContributorId string


var RoleAssignmentName = guid(resourceGroup().name, ManagedIdentityId, NetworkContributorId)


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', NetworkContributorId)
    principalId: ManagedIdentityId
    principalType: 'ServicePrincipal'
  }
}
