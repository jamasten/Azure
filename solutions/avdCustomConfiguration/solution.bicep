param Location string
param NamePrefix string
param NumberOfVms int
param ScriptUri string
param SentinelLogAnalyticsWorkspaceName string = ''
param SentinelLogAnalyticsWorkspaceResourceGroupName string = ''
param Timestamp string = utcNow('yyyyMMddhhmmss')
param VirtualDesktopOptimizationToolUrl string = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
param VirtualMachineIndex int


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: SentinelLogAnalyticsWorkspaceName
  scope: resourceGroup(SentinelLogAnalyticsWorkspaceResourceGroupName)
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
        ScriptUri
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File script.ps1 -SentinelWorkspaceId ${logAnalyticsWorkspace.properties.customerId} -SentinelWorkspaceKey ${listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey} -VirtualDesktopOptimizationToolUrl ${VirtualDesktopOptimizationToolUrl}'
    }
  }
}]
