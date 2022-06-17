param AutomationAccountName string
param HostPoolName string
param Location string
param LogAnalyticsWorkspaceName string
param LogAnalyticsWorkspaceRetention int
param LogAnalyticsWorkspaceSku string
param PooledHostPool bool
param Tags object
param WorkspaceName string


var HostPoolLogs = [
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
var NetworkData = [
  {
    category: 'NetworkData'
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


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
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
resource windowsEvents 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for (item, i) in WindowsEvents: {
  name: '${logAnalyticsWorkspace.name}/WindowsEvent${i}'
  tags: Tags
  kind: 'WindowsEvent'
  properties: {
    eventLogName: item.name
    eventTypes: item.types
  }
}]

@batchSize(1)
resource windowsPerformanceCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = [for (item, i) in WindowsPerformanceCounters: {
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
    windowsEvents
  ]
}]

resource workspaceDiagnostics 'Microsoft.DesktopVirtualization/workspaces/providers/diagnosticsettings@2017-05-01-preview' = {
  name: '${WorkspaceName}/Microsoft.Insights/diag-${WorkspaceName}'
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
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName)
  }
}

resource hostPoolDiagnostics 'Microsoft.DesktopVirtualization/hostPools/providers/diagnosticsettings@2017-05-01-preview' = {
  name: '${HostPoolName}/Microsoft.Insights/diag-${HostPoolName}'
  properties: {
    logs: environment().name == 'AzureCloud' ? union(HostPoolLogs,NetworkData) : HostPoolLogs //adding NetworkData for AzureCloud, not available in AzureUSGovernment, 2/10/2022
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', LogAnalyticsWorkspaceName)
  }
}

resource diagnostics 'Microsoft.Automation/automationAccounts/providers/diagnosticsettings@2017-05-01-preview' = if(PooledHostPool) {
  name: '${AutomationAccountName}/Microsoft.Insights/diag-${AutomationAccountName}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}
