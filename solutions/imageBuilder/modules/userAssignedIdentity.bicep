param Environment string
param Location string
param LocationShortName string


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uai-aib-${Environment}-${LocationShortName}'
  location: Location
}


output userAssignedIdentityPrincipalId string = userAssignedIdentity.properties.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.id
