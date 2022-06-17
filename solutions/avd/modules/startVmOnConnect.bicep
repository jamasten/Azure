targetScope = 'subscription'

param PrincipalId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid('StartVmOnConnect', subscription().id)
  properties: {
    assignableScopes: [
      subscription().id
    ]
    roleName: 'StartVmOnConnect_${subscription().subscriptionId}'
    description: 'Allow AVD session hosts to be started when needed.'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.Compute/virtualMachines/instanceView/read'
        ]
        notActions: []
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid('Azure Virtual Desktop', 'StartVmOnConnect', subscription().id)
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: PrincipalId
  }
}
