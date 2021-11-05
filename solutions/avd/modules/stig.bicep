param AutomationAccountName string
param Location string
param SessionHostCount int
param SessionHostIndex int
param Timestamp string
param VmName string
param VmResourceGroupName string

var ConfigurationName = 'Windows'
var Modules = [
  {
    name: 'AccessControlDSC'
    uri: 'https://www.powershellgallery.com/api/v2/package/AccessControlDSC/1.4.1'
  }
  {
    name: 'AuditPolicyDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/AuditPolicyDsc/1.4.0.0'
  }
  {
    name: 'AuditSystemDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/AuditSystemDsc/1.1.0'
  }
  {
    name: 'CertificateDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/CertificateDsc/5.0.0'
  }
  {
    name: 'ComputerManagementDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/8.4.0'
  }
  {
    name: 'FileContentDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/FileContentDsc/1.3.0.151'
  }
  {
    name: 'GPRegistryPolicyDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/GPRegistryPolicyDsc/1.2.0'
  }
  {
    name: 'nx'
    uri: 'https://www.powershellgallery.com/api/v2/package/nx/1.0'
  }
  {
    name: 'PSDscResources'
    uri: 'https://www.powershellgallery.com/api/v2/package/PSDscResources/2.12.0.0'
  }
  {
    name: 'SecurityPolicyDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/SecurityPolicyDsc/2.10.0.0'
  }
  {
    name: 'SqlServerDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/SqlServerDsc/13.3.0'
  }
  {
    name: 'WindowsDefenderDsc'
    uri: 'https://www.powershellgallery.com/api/v2/package/WindowsDefenderDsc/2.1.0'
  }
  {
    name: 'xDnsServer'
    uri: 'https://www.powershellgallery.com/api/v2/package/xDnsServer/1.16.0.0'
  }
  {
    name: 'xWebAdministration'
    uri: 'https://www.powershellgallery.com/api/v2/package/xWebAdministration/3.2.0'
  }
  {
    name: 'PowerSTIG'
    uri: 'https://www.powershellgallery.com/api/v2/package/PowerSTIG/4.10.1'
  }
]

resource AutomationAccountName_resource 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: AutomationAccountName
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

@batchSize(1)
resource AutomationAccountName_Modules_name 'Microsoft.Automation/automationAccounts/modules@2015-10-31' = [for item in Modules: {
  name: '${AutomationAccountName}/${item.name}'
  location: Location
  properties: {
    contentLink: {
      uri: item.uri
    }
  }
  dependsOn: [
    AutomationAccountName_resource
  ]
}]

resource AutomationAccountName_ConfigurationName 'Microsoft.Automation/automationAccounts/configurations@2015-10-31' = {
  parent: AutomationAccountName_resource
  name: '${ConfigurationName}'
  location: Location
  properties: {
    source: {
      type: 'uri'
      value: 'https://raw.githubusercontent.com/battelle-cube/azure-avd-automation/main/solutions/avd/configurations/Windows.ps1'
      version: Timestamp
    }
    parameters: {}
    description: 'Hardens the VM using the Azure STIG Template'
  }
  dependsOn: [
    AutomationAccountName_Modules_name
  ]
}

resource AutomationAccountName_name 'Microsoft.Automation/automationAccounts/compilationjobs@2020-01-13-preview' = {
  parent: AutomationAccountName_resource
  name: '${guid(deployment().name)}'
  location: Location
  properties: {
    configuration: {
      name: ConfigurationName
    }
  }
  dependsOn: [
    AutomationAccountName_Modules_name
    AutomationAccountName_ConfigurationName
  ]
}

module DscExtensionDeployment './nested_DscExtensionDeployment.bicep' = {
  name: 'DscExtensionDeployment'
  scope: resourceGroup(VmResourceGroupName)
  params: {
    AutomationAccountName: AutomationAccountName
    AutomationAccountResourceGroupName: resourceGroup().name
    ConfigurationName: ConfigurationName
    Location: Location
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    Timestamp: Timestamp
    VmName: VmName
  }
  dependsOn: [
    AutomationAccountName_name
  ]
}