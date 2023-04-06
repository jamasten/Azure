param DeploymentScriptName string
param DeployOffice bool
param DeployProject bool
param DeployVisio bool
param Location string
param StorageAccountName string
param StorageContainerName string
param Tags object


var FileName = 'office365x64.xml'
var O365ConfigHeader = '<Add OfficeClientEdition="64" Channel="Current"><Add OfficeClientEdition="64" Channel="Current">'
var O365AddOffice = DeployOffice ? '<Product ID="O365ProPlusRetail"><Language ID="en-us" /></Product>' : ''
var O365AddProject = DeployProject ? '<Product ID="ProjectProRetail"><Language ID="en-us" /></Product>' : ''
var O365AddVisio = DeployVisio ? '<Product ID="VisioProRetail"><Language ID="en-us" /></Product>' : ''
var O365ConfigFooter = '</Add><Updates Enabled="FALSE" /><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/><Property Name="SharedComputerLicensing" Value="1"/></Configuration>'
var Content = '${O365ConfigHeader}${O365AddOffice}${O365AddProject}${O365AddVisio}${O365ConfigFooter}'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: StorageAccountName
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${DeploymentScriptName}-onedrive'
  location: Location
  tags: Tags
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: Content
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${FileName} && az storage blob upload -f ${FileName} -c ${StorageContainerName} -n ${FileName}'
  }
}
