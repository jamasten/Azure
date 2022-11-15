param PolicyAssignmentId string

resource exemption 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = {
  name: 'exempt-aib-staging-resource-group'
  properties: {
    assignmentScopeValidation: 'Default'
    description: 'Exempts the AIB staging resource group to prevent issues with building images.'
    displayName: 'AIB staging resource group'
    exemptionCategory: 'Mitigated'
    expiresOn: null
    metadata: null
    policyAssignmentId: PolicyAssignmentId
    policyDefinitionReferenceIds: []
    resourceSelectors: []
  }
}
