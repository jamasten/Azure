param Location string
param LogAnalyticsWorkspaceResourceId string
param MultiHomeMicrosoftMonitoringAgent bool
param Tags object
param Timestamp string
param VmName string


var WorkspaceId = reference(LogAnalyticsWorkspaceResourceId, '2015-03-20').customerId
var WorkspaceKey = listKeys(LogAnalyticsWorkspaceResourceId, '2015-03-20').primarySharedKey


resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-08-01' existing = {
  name: VmName
}

resource extension_MicrosoftMonitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if(!MultiHomeMicrosoftMonitoringAgent) {
  parent: virtualMachine
  name: 'MicrosoftMonitoringAgent'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: WorkspaceId
    }
    protectedSettings: {
      workspaceKey: WorkspaceKey
    }
  }
}

resource extension_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if(MultiHomeMicrosoftMonitoringAgent) {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/avdRemoveStalePersonalSessionHosts/artifacts/Set-MicrosoftMonitoringAgent.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-MicrosoftMonitoringAgent.ps1 -WorkspaceId ${WorkspaceId} -WorkspaceKey ${WorkspaceKey}'
    }
  }
}
