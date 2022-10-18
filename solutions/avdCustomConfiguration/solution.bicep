param AvdInsightsLogAnalyticsWorkspaceResourceId string = ''
param Location string
param NamePrefix string
param NumberOfVms int
@secure()
param SasToken string = ''
param ScriptUri string
param SentinelLogAnalyticsWorkspaceResourceId string = ''
param Timestamp string = utcNow('yyyyMMddhhmmss')
param VirtualDesktopOptimizationToolUrl string = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
param VirtualMachineIndex int


var SentinelWorkspaceName = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[-1]
var SentinelWorkspaceResouceGroupName = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[4]
var SentinelWorkspaceSubscriptionId = split(SentinelLogAnalyticsWorkspaceResourceId, '/')[2]


resource microsoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, length(range(VirtualMachineIndex, NumberOfVms))): if(!empty(AvdInsightsLogAnalyticsWorkspaceResourceId)) {
  name: '${NamePrefix}-${range(VirtualMachineIndex, NumberOfVms)[i]}/MicrosoftMonitoringAgent'
  location: Location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(AvdInsightsLogAnalyticsWorkspaceResourceId, '2015-03-20').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(AvdInsightsLogAnalyticsWorkspaceResourceId, '2015-03-20').primarySharedKey
    }
  }
}]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if(!empty(AvdInsightsLogAnalyticsWorkspaceResourceId) && !empty(SentinelLogAnalyticsWorkspaceResourceId)) {
  name: SentinelWorkspaceName
  scope: resourceGroup(SentinelWorkspaceSubscriptionId, SentinelWorkspaceResouceGroupName)
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, length(range(VirtualMachineIndex, NumberOfVms))): {
  name: '${NamePrefix}-${range(VirtualMachineIndex, NumberOfVms)[i]}/CustomScriptExtension'
  location: Location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptUri}${SasToken}'
        contains(VirtualDesktopOptimizationToolUrl, environment().suffixes.storage) ? '${VirtualDesktopOptimizationToolUrl}${SasToken}' : VirtualDesktopOptimizationToolUrl
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File script.ps1 -SentinelWorkspaceId ${!empty(AvdInsightsLogAnalyticsWorkspaceResourceId) && !empty(SentinelLogAnalyticsWorkspaceResourceId) ? logAnalyticsWorkspace.properties.customerId : ''} -SentinelWorkspaceKey ${!empty(AvdInsightsLogAnalyticsWorkspaceResourceId) && !empty(SentinelLogAnalyticsWorkspaceResourceId) ? listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey : ''}'
    }
  }
  dependsOn: [
    microsoftMonitoringAgent
  ]
}]
