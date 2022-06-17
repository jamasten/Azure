param HostPoolName string
param Location string
param ManagedIdentityResourceId string
param NetAppFileShare string
param ResourceGroup string
param SasToken string
param ScriptsUri string
param SessionHostCount int
param SessionHostIndex int
param StorageAccountName string
param StorageShardIndex int
param StorageSolution string
param Tags object
param Timestamp string
param VmName string


resource getPreviousSessionHosts 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getPreviousSessionHosts'
  location: Location
  tags: Tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityResourceId}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-ResourceGroup ${ResourceGroup}'
    scriptContent: '''param([string]$ResourceGroup);$DeploymentScriptOutputs = @{};$DeploymentScriptOutputs['vms'] = $VirtualMachines'''
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptsUri}Set-SessionHostStorageShardConfiguration.ps1${SasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -Environment ${environment().name} -HostPoolName ${HostPoolName} -NetAppFileShare ${NetAppFileShare} -StorageAccountName ${StorageAccountName} -StorageShardIndex ${StorageShardIndex} -StorageSolution ${StorageSolution}'
    }
  }
  dependsOn: [
    getPreviousSessionHosts
  ]
}]
