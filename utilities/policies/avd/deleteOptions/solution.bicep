targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'VirtualMachineDeleteOptions'
  properties: {
    description: 'Enable the delete option virtual machine disks and network interfaces'
    displayName: 'Enable Virtual Machine Delete Options'
    mode: 'All'
    parameters: {}
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Compute/virtualMachines'
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor
          ]
          operations: [
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/virtualMachines/storageProfile.osDisk.deleteOption'
              value: 'Delete'
            }
            {
              operation: 'addOrReplace'
              field: 'Microsoft.Compute/virtualMachines/networkProfile.networkInterfaces[*].deleteOption'
              value: 'Delete'
            }
          ]
        }
      }
    }
    policyType: 'Custom'
  }
}
