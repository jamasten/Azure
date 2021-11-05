param AppGroupName string
param CustomRdpProperty string
param HostPoolName string
param HostPoolType string
param Location string
param LogAnalyticsWorkspaceName string
param LogAnalyticsWorkspaceRetention int
param LogAnalyticsWorkspaceSku string
param MaxSessionLimit int
param newOrExisting string
param SecurityPrincipalId string
param StartVmOnConnect bool
param Tags object
param Timestamp string = utcNow('u')
param ValidationEnvironment bool
param VmTemplate string
param WorkspaceName string

var HostPoolLogs_AzureCloud = [
  {
    category: 'Checkpoint'
    enabled: true
  }
  {
    category: 'Error'
    enabled: true
  }
  {
    category: 'Management'
    enabled: true
  }
  {
    category: 'Connection'
    enabled: true
  }
  {
    category: 'HostRegistration'
    enabled: true
  }
  {
    category: 'AgentHealthStatus'
    enabled: true
  }
]
var HostPoolLogs_AzureUsGov = [
  {
    category: 'Checkpoint'
    enabled: true
  }
  {
    category: 'Error'
    enabled: true
  }
  {
    category: 'Management'
    enabled: true
  }
  {
    category: 'Connection'
    enabled: true
  }
  {
    category: 'HostRegistration'
    enabled: true
  }
]
var WindowsEvents = [
  {
    name: 'Microsoft-FSLogix-Apps/Operational'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
      {
        eventType: 'Information'
      }
    ]
  }
  {
    name: 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
      {
        eventType: 'Information'
      }
    ]
  }
  {
    name: 'System'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
  {
    name: 'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
      {
        eventType: 'Information'
      }
    ]
  }
  {
    name: 'Microsoft-FSLogix-Apps/Admin'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
      {
        eventType: 'Information'
      }
    ]
  }
  {
    name: 'Application'
    types: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
]
var WindowsPerformanceCounters = [
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Disk Transfers/sec'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Current Disk Queue Length'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Disk Reads/sec'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Free Space'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Read'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Disk Writes/sec'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Write'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Free Megabytes'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: 'C:'
    intervalSeconds: 60
    counterName: '% Free Space'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: 'C:'
    intervalSeconds: 30
    counterName: 'Avg. Disk Queue Length'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: 'C:'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Transfer'
  }
  {
    objectName: 'LogicalDisk'
    instanceName: 'C:'
    intervalSeconds: 30
    counterName: 'Current Disk Queue Length'
  }
  {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Committed Bytes In Use'
  }
  {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Available MBytes'
  }
  {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Available Mbytes'
  }
  {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Page Faults/sec'
  }
  {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Pages/sec'
  }
  {
    objectName: 'Network Adapter'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Bytes Sent/sec'
  }
  {
    objectName: 'Network Adapter'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Bytes Received/sec'
  }
  {
    objectName: 'Network Interface'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Bytes Total/sec'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk Bytes/Transfer'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk Bytes/Read'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Write'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Read'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk Bytes/Write'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Avg. Disk sec/Transfer'
  }
  {
    objectName: 'PhysicalDisk'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Avg. Disk Queue Length'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'IO Write Operations/sec'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'IO Read Operations/sec'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Thread Count'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% User Time'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Working Set'
  }
  {
    objectName: 'Process'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Processor Time'
  }
  {
    objectName: 'Processor'
    instanceName: '_Total'
    intervalSeconds: 60
    counterName: '% Processor Time'
  }
  {
    objectName: 'Processor Information'
    instanceName: '_Total'
    intervalSeconds: 30
    counterName: '% Processor Time'
  }
  {
    objectName: 'RemoteFX Graphics'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Frames Skipped/Second - Insufficient Server Resources'
  }
  {
    objectName: 'RemoteFX Graphics'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Average Encoding Time'
  }
  {
    objectName: 'RemoteFX Graphics'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Frames Skipped/Second - Insufficient Client Resources'
  }
  {
    objectName: 'RemoteFX Graphics'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Frames Skipped/Second - Insufficient Network Resources'
  }
  {
    objectName: 'RemoteFX Network'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Current UDP Bandwidth'
  }
  {
    objectName: 'RemoteFX Network'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Current TCP Bandwidth'
  }
  {
    objectName: 'RemoteFX Network'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Current TCP RTT'
  }
  {
    objectName: 'RemoteFX Network'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Current UDP RTT'
  }
  {
    objectName: 'System'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Processor Queue Length'
  }
  {
    objectName: 'Terminal Services'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Inactive Sessions'
  }
  {
    objectName: 'Terminal Services'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Total Sessions'
  }
  {
    objectName: 'Terminal Services'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Active Sessions'
  }
  {
    objectName: 'Terminal Services Session'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Processor Time'
  }
  {
    objectName: 'User Input Delay per Process'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Max Input Delay'
  }
  {
    objectName: 'User Input Delay per Session'
    instanceName: '*'
    intervalSeconds: 30
    counterName: 'Max Input Delay'
  }
]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: LogAnalyticsWorkspaceName
  location: Location
  tags: Tags
  properties: {
    sku: {
      name: LogAnalyticsWorkspaceSku
    }
    retentionInDays: LogAnalyticsWorkspaceRetention
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@batchSize(1)
resource logAnalyticsWorkspace_WindowsEvents 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for (item, i) in WindowsEvents: {
  name: '${logAnalyticsWorkspace.name}/WindowsEvent${i}'
  tags: Tags
  kind: 'WindowsEvent'
  properties: {
    eventLogName: item.name
    eventTypes: item.types
  }
}]

@batchSize(1)
resource logAnalyticsWorkspace_WindowsPerformanceCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for (item, i) in WindowsPerformanceCounters: {
  name: '${logAnalyticsWorkspace.name}/WindowsPerformanceCounter${i}'
  tags: Tags
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: item.objectName
    instanceName: item.instanceName
    intervalSeconds: item.intervalSeconds
    counterName: item.counterName
  }
  dependsOn: [
    logAnalyticsWorkspace_WindowsEvents
  ]
}]

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = {
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
    customRdpProperty: CustomRdpProperty
    personalDesktopAssignmentType: contains(HostPoolType, 'Personal') ? split(HostPoolType, ' ')[1] : null
    startVMOnConnect: StartVmOnConnect
    vmTemplate: VmTemplate

  }
}

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (newOrExisting == 'new') {
  scope: hostPool
  name: 'diag-${hostPool.name}'
  properties: {
    logs: ((environment().name == 'AzureCloud') ? HostPoolLogs_AzureCloud : HostPoolLogs_AzureUsGov)
    workspaceId: logAnalyticsWorkspace.id
  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = if (newOrExisting == 'new') {
  name: AppGroupName
  location: Location
  tags: Tags
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
  }
}

resource appGroupAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = if (newOrExisting == 'new') {
  scope: appGroup
  name: guid(HostPoolName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalId: SecurityPrincipalId
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = if (newOrExisting == 'new') {
  name: WorkspaceName
  location: Location
  tags: Tags
  properties: {
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (newOrExisting == 'new') {
  scope: workspace
  name: 'diag-${workspace.name}'
  properties: {
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
      {
        category: 'Feed'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}
