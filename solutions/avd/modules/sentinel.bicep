param Sentinel bool
param SentinelLogAnalyticsWorkspaceName string
param SentinelLogAnalyticsWorkspaceResourceGroupName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if(Sentinel) {
  name: SentinelLogAnalyticsWorkspaceName
  scope: resourceGroup(SentinelLogAnalyticsWorkspaceResourceGroupName)
}

output sentinelWorkspaceId string = Sentinel ? logAnalyticsWorkspace.properties.customerId : 'NotApplicable'
output sentinelWorkspaceResourceId string = Sentinel ? logAnalyticsWorkspace.id : 'NotApplicable'
