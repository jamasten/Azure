param HostPoolName string
param HostPoolResourceGroupName string
param Location string
param Timestamp string

var ManagedIdentityName_var = 'uami-drainmode'
var RoleAssignmentName_var = guid(resourceGroup().id, ManagedIdentityName_var)

resource ManagedIdentityName 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: ManagedIdentityName_var
  location: Location
}

resource RoleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: RoleAssignmentName_var
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(ManagedIdentityName.id, '2018-11-30').principalId
    principalType: 'ServicePrincipal'
  }
}

resource ds_drainmode 'Microsoft.Resources/deploymentScripts@2019-10-01-preview' = {
  name: 'ds-drainmode'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ManagedIdentityName.id}': {}
    }
  }
  location: Location
  kind: 'AzurePowerShell'
  tags: {}
  properties: {
    azPowerShellVersion: '5.4'
    cleanupPreference: 'OnSuccess'
    scriptContent: '\r\n                    param(\r\n                        [string] [Parameter(Mandatory=$true)] $HostPool,\r\n                        [string] [Parameter(Mandatory=$true)] $ResourceGroup\r\n                    )\r\n\r\n                    $SessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool).Name\r\n                    foreach($SessionHost in $SessionHosts)\r\n                    {\r\n                        $Name = ($SessionHost -split \'/\')[1]\r\n                        Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $Name -AllowNewSession:$False\r\n                    }\r\n\r\n                    $DeploymentScriptOutputs = @{}\r\n                '
    arguments: ' -ResourceGroup ${HostPoolResourceGroupName} -HostPool ${HostPoolName}'
    forceUpdateTag: Timestamp
    retentionInterval: 'P1D'
    timeout: 'PT30M'
  }
  dependsOn: [
    RoleAssignmentName
  ]
}