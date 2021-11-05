param AutomationAccountName string
param AutomationAccountResourceGroupName string
param ConfigurationName string
param Location string
param SessionHostCount int
param SessionHostIndex int
param Timestamp string
param VmName string

resource VmName_SessionHostIndex_3_0_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/DSC'
  location: Location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      Items: {
        registrationKeyPrivate: listKeys(resourceId(AutomationAccountResourceGroupName, 'Microsoft.Automation/automationAccounts', AutomationAccountName), '2018-06-30').Keys[0].value
      }
    }
    settings: {
      Properties: [
        {
          Name: 'RegistrationKey'
          Value: {
            UserName: 'PLACEHOLDER_DONOTUSE'
            Password: 'PrivateSettingsRef:registrationKeyPrivate'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'RegistrationUrl'
          Value: reference(resourceId(AutomationAccountResourceGroupName, 'Microsoft.Automation/automationAccounts', AutomationAccountName), '2018-06-30').registrationUrl
          TypeName: 'System.String'
        }
        {
          Name: 'NodeConfigurationName'
          Value: '${ConfigurationName}.localhost'
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationMode'
          Value: 'ApplyandAutoCorrect'
          TypeName: 'System.String'
        }
        {
          Name: 'RebootNodeIfNeeded'
          Value: true
          TypeName: 'System.Boolean'
        }
        {
          Name: 'ActionAfterReboot'
          Value: 'ContinueConfiguration'
          TypeName: 'System.String'
        }
        {
          Name: 'Timestamp'
          Value: Timestamp
          TypeName: 'System.String'
        }
      ]
    }
  }
}]