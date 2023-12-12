targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'EnableAcceleratedNetworking'
  properties: {
    description: 'Enable accelerated networking on network interfaces for virtual machines'
    displayName: 'Enable Accelerated Networking'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Network/networkInterfaces'
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
          ]
          operations: [
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Network/networkInterfaces/enableAcceleratedNetworking'
              value: true
            }
          ]
        }
      }
    }
    policyType: 'Custom'
  }
}
