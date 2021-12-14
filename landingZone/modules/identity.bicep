param DomainControllerName string
param DomainControllerDiskName string
param DomainControllerNicName string
param DomainName string
param DomainServices string
param Location string
param ResourceGroupNames array
@secure()
param VmPassword string
param VmUsername string
param VnetName string


resource domainServices 'Microsoft.AAD/DomainServices@2021-03-01' = if(DomainServices == 'AzureActiveDirectory') {
  name: DomainName
  location: Location
  properties: {
    domainName: DomainName
    filteredSync: 'Disabled'
    domainConfigurationType: 'FullySynced'
    notificationSettings: {
      notifyGlobalAdmins: 'Enabled'
      notifyDcAdmins: 'Enabled'
      additionalRecipients: []
    }
    replicaSets: [
      {
        subnetId: resourceId(ResourceGroupNames[1], 'Microsoft.Network/virtualNetworks/subnets', VnetName, 'AzureADDSSubnet')
        location: Location
      }
    ]
    sku: 'Standard'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2018-08-01' = if(DomainServices == 'ActiveDirectory') {
  name: DomainControllerNicName
  location: Location
  tags: {}
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig0'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.3.4'
          subnet: {
            id: resourceId(ResourceGroupNames[1], 'Microsoft.Network/virtualNetworks/subnets', VnetName, 'SharedServices')
          }
        }
      }
    ]
  }
  dependsOn: []
}

resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = if(DomainServices == 'ActiveDirectory') {
  name: DomainControllerName
  location: Location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: DomainControllerName
      adminUsername: VmUsername
      adminPassword: VmPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: DomainControllerDiskName
        caching: 'None'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource dsc 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = if(DomainServices == 'ActiveDirectory') {
  parent: vm
  name: 'DSC'
  location: Location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      Items: {
        VmPassword: VmPassword
      }
    }
    settings: {
      wmfVersion: 'latest'
      modulesUrl: 'https://github.com/battelle-cube/terraform-cube-avd/blob/main/landingZone/dsc/ActiveDirectoryForest.zip?raw=true'
      configurationFunction: 'ActiveDirectoryForest.ps1\\ActiveDirectoryForest'
      properties: [
        {
          Name: 'Domain'
          Value: DomainName
          TypeName: 'System.String'
        }
        {
          Name: 'DomainCreds'
          Value: {
            UserName: VmUsername
            Password: 'PrivateSettingsRef:VmPassword'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
      ]
    }
  }
}
