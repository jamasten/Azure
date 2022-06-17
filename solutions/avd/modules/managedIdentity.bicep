param Location string
param ManagedIdentityName string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName
  location: Location
}


output principalId string = managedIdentity.properties.principalId
output resourceIdentifier string = managedIdentity.id
