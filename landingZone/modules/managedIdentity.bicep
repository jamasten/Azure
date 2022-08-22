param Location string
param ManagedIdentityName string
param NetworkContributorId string

var RoleAssignmentName = guid(resourceGroup().name, ManagedIdentityName, NetworkContributorId)

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', NetworkContributorId)
    principalId: reference(managedIdentity.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}

output principalId string = reference(managedIdentity.id, '2018-11-30').principalId
