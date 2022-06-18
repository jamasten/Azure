param AppGroupName string
param CustomRdpProperty string
param DomainServices string
param HostPoolName string
param HostPoolType string
param Location string
param MaxSessionLimit int
param RoleDefinitionIds object
param SecurityPrincipalIds array
param StartVmOnConnect bool
param Tags object
param Timestamp string = utcNow('u')
param ValidationEnvironment bool
param VmTemplate string
param WorkspaceName string


var CustomRdpProperty_Complete = contains(DomainServices, 'None') ? '${CustomRdpProperty}targetisaadjoined:i:1' : CustomRdpProperty


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-03-09-preview' = {
  name: HostPoolName
  location: Location
  tags: Tags
  properties: {
    hostPoolType: split(HostPoolType, ' ')[0]
    maxSessionLimit: MaxSessionLimit
    loadBalancerType: contains(HostPoolType, 'Pooled') ? split(HostPoolType, ' ')[1] : null
    validationEnvironment: ValidationEnvironment
    registrationInfo: {
      expirationTime: dateTimeAdd(Timestamp, 'PT2H')
      registrationTokenOperation: 'Update'
    }
    preferredAppGroupType: 'Desktop'
    customRdpProperty: CustomRdpProperty_Complete
    personalDesktopAssignmentType: contains(HostPoolType, 'Personal') ? split(HostPoolType, ' ')[1] : null
    startVMOnConnect: StartVmOnConnect // https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect
    vmTemplate: VmTemplate

  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-03-09-preview' = {
  name: AppGroupName
  location: Location
  tags: Tags
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
  }
}

resource appGroupAssignment 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = [for i in range(0, length(SecurityPrincipalIds)): {
  scope: appGroup
  name: guid(SecurityPrincipalIds[i], RoleDefinitionIds.desktopVirtualizationUser, AppGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.desktopVirtualizationUser)
    principalId: SecurityPrincipalIds[i]
  }
}]

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-03-09-preview' = {
  name: WorkspaceName
  location: Location
  tags: Tags
  properties: {
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}
