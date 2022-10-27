param Location string
param LogAnalyticsWorkspaceName string
param SessionHostExpirationInDays int
param Tags object


var LogAnalyticsWorkspaceRetention = SessionHostExpirationInDays <= 30 ? 30 : SessionHostExpirationInDays


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: LogAnalyticsWorkspaceName
  location: Location
  tags: Tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: LogAnalyticsWorkspaceRetention
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


output resourceId string = logAnalyticsWorkspace.id
