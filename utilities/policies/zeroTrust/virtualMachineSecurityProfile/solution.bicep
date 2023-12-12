targetScope = 'subscription'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'ZeroTrustSecurityProfileConfiguration'
  properties: {
    description: 'Enable zero trust security profile configuration for virtual machines'
    displayName: 'Enable zero trust security profile configuration'
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
              field: 'Microsoft.Compute/virtualMachines/securityProfile'
              value: {
                encryptionAtHost: true
                securityType: 'TrustedLaunch'
                uefiSettings: {
                  secureBootEnabled: true
                  vtpmEnabled: true
                }
              }
            }
          ]
        }
      }
    }
    policyType: 'Custom'
  }
}
