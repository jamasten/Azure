param SentinelLogAnalyticsWorkspaceName string
param SentinelLogAnalyticsWorkspaceResourceGroupName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: SentinelLogAnalyticsWorkspaceName
  scope: resourceGroup(SentinelLogAnalyticsWorkspaceResourceGroupName)
}

output sentinelWorkspaceId string = logAnalyticsWorkspace.properties.customerId
output sentinelWorkspaceResourceId string = logAnalyticsWorkspace.id
