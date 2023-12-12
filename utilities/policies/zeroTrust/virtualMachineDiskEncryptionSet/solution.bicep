targetScope = 'subscription'

param diskEncryptionSetResourceId string

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'DiskEncryptionSetForVirtualMachines'
  properties: {
    description: 'Enable disk encryption set for virtual machines'
    displayName: 'Enable disk encryption set for virtual machines'
    mode: 'All'
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
              field: 'Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.diskEncryptionSet.id'
              value: diskEncryptionSetResourceId
            }
          ]
        }
      }
    }
    policyType: 'Custom'
  }
}
