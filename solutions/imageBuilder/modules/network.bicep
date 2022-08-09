param IdentityName string
param ImagingResourceGroupName string
param Role string


resource _8f86a747_5ec8_48bc_86d0_d0915160e07d 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: '8f86a747-5ec8-48bc-86d0-d0915160e07d'
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', Role)
    principalId: reference('${subscription().id}/resourceGroups/${ImagingResourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${IdentityName}', '2018-11-30', 'Full').properties.principalId
    principalType: 'ServicePrincipal'
  }
}
