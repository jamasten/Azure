targetScope = 'subscription'


param DrainMode bool
param FslogixStorage string
param Location string
param ManagedIdentityName string
param ResourceGroups array
param RoleDefinitionIds object
param Timestamp string
param VirtualNetworkResourceGroup string


var RoleAssignments = [
  {
    condition: DrainMode // Supports drain mode on session hosts
    resourceGroup: ResourceGroups[2] // Management resource group
    roleDefinitionId: RoleDefinitionIds.desktopVirtualizationSessionHostOperator // https://docs.microsoft.com/en-us/azure/virtual-desktop/rbac#desktop-virtualization-session-host-operator
  }

  {
    condition: contains(FslogixStorage, 'PrivateEndpoint') // Supports private endpoints on Azure Files
    resourceGroup: VirtualNetworkResourceGroup // Networking resource group
    roleDefinitionId: RoleDefinitionIds.networkContributor
  }
]


resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = {
  name: guid('DeploymentScriptContributor', subscription().id)
  properties: {
    assignableScopes: [
      subscription().id
    ]
    roleName: 'DeploymentScriptContributor_${subscription().subscriptionId}'
    description: 'Allow Deployment Scripts to deploy required resources to run scripts.'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/*'
          'Microsoft.ContainerInstance/containerGroups/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/deploymentScripts/*'
          'Microsoft.ManagedIdentity/userAssignedIdentities/assign/action'
        ]
        notActions: []
      }
    ]
  }
}

// User Assigned Managed Identity
module userAssignedIdentity 'userAssignedManagedIdentity.bicep' = {
  name: 'UserAssignedManagedIdentity_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    RoleDefinitionId: roleDefinition.id
  }
}

// Role Assignment for Validation
// This role assignment is required to collect validation information
resource roleAssignment_validation 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(ManagedIdentityName, RoleDefinitionIds.reader, subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.reader)
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignments on Resource Groups 
// These role assignments are needed to support different features based on parameter values and are conditionally deployed
module roleAssignments 'roleAssignments.bicep' = [for i in range(0, length(RoleAssignments)): {
  name: 'RoleAssignments_${RoleAssignments[i].resourceGroup}_${Timestamp}'
  scope: resourceGroup(RoleAssignments[i].resourceGroup)
  params: {
    Condition: RoleAssignments[i].condition
    PrincipalId: userAssignedIdentity.outputs.principalId
    RoleDefinitionId: RoleAssignments[i].roleDefinitionId
  }
}]


output principalId string = userAssignedIdentity.outputs.principalId
output resourceIdentifier string = userAssignedIdentity.outputs.resourceIdentifier
