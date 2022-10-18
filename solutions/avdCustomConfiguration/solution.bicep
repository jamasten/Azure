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


var MicrosoftMonitoringAgent = empty(AvdInsightsLogAnalyticsWorkspaceResourceId) ? false : true
var SentinelWorkspaceId = empty(SentinelLogAnalyticsWorkspaceResourceId) ? 'NotApplicable' : reference(SentinelLogAnalyticsWorkspaceResourceId, '2021-06-01').properties.customerId
var SentinelWorkspaceKey = empty(SentinelLogAnalyticsWorkspaceResourceId) ? 'NotApplicable' : listKeys(SentinelLogAnalyticsWorkspaceResourceId, '2021-06-01').primarySharedKey


resource microsoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, length(range(VirtualMachineIndex, NumberOfVms))): if(MicrosoftMonitoringAgent) {
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
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File script.ps1 -MicrosoftMonitoringAgent ${MicrosoftMonitoringAgent} -SentinelWorkspaceId ${SentinelWorkspaceId} -SentinelWorkspaceKey ${SentinelWorkspaceKey}'
    }
  }
  dependsOn: [
    microsoftMonitoringAgent
  ]
}]
