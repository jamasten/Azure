param Location string
param ManagedIdentityName string
param NetworkContributorId string

var RoleAssignmentName = guid(resourceGroup().name, ManagedIdentityName, NetworkContributorId)

resource ManagedIdentityName_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', NetworkContributorId)
    principalId: reference(ManagedIdentityName_resource.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}

output principalId string = reference(ManagedIdentityName_resource.id, '2018-11-30').principalId
