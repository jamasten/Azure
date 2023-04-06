param DeployFSLogix bool
param DeployOffice bool
param DeployOneDrive bool
param DeployProject bool
param DeployTeams bool
param DeployVirtualDesktopOptimizationTool bool
param DeployVisio bool
param ImageDefinitionResourceId string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param ImageStorageAccountType string
param ImageTemplateName string
param ImageVersion string
param Location string
param StagingResourceGroupName string
param StorageUri string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityResourceId string
param VirtualMachineSize string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


var CreateTempDir = [
  {
    type: 'PowerShell'
    name: 'Create TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'New-Item -Path "C:\\" -Name "temp" -ItemType "Directory" -Force | Out-Null; Write-Host "Created Temp Directory"'
    ]
  }
]

var FSLogixType = contains(ImageSku, 'avd') ? [
  {
    type: 'PowerShell'
    name: 'Download FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-FSLogix.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Uninstall FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Remove-FSLogix.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
  {
    type: 'PowerShell'
    name: 'Install FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Add-FSLogix.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
] : [
  {
    type: 'PowerShell'
    name: 'Download FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-FSLogix.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}fslogix.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
]
var FSLogix = DeployFSLogix ? FSLogixType : []
var Functions = [
  {
    type: 'File'
    name: 'Tenant ID'
    sourceUri: '${StorageUri}Set-RegistrySetting.ps1'
    destination: 'C:\\temp\\Set-RegistrySetting.ps1'
  }
]
var Office = DeployOffice || DeployVisio || DeployProject ? [
  {
    type: 'PowerShell'
    name: 'Download Microsoft Office 365'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-O365.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install Microsoft Office 365'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Add-O365.ps1'
  }
] : []
var OneDriveType = ImageSku == 'office-365' ? [
  {
    type: 'PowerShell'
    name: 'Download OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-OneDrive.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Uninstall OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Remove-OneDrive.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
  {
    type: 'PowerShell'
    name: 'Install OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Add-OneDrive.ps1'
  }
] : [
  {
    type: 'PowerShell'
    name: 'Download OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-OneDrive.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install OneDrive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Add-OneDrive.ps1'
  }
]
var OneDrive = DeployOneDrive ? OneDriveType : []
var Teams = DeployTeams ? [
  {
    type: 'PowerShell'
    name: 'Download Teams'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-Teams.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Install Teams'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Add-Teams.ps1'
  }
] : []
var VDOT = DeployVirtualDesktopOptimizationTool ? [
  {
    type: 'PowerShell'
    name: 'Download the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Get-VDOT.ps1'
  }
  {
    type: 'PowerShell'
    name: 'Execute the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}Set-VDOT.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
] : []
var RemoveTempDir = [
  {
    type: 'PowerShell'
    name: 'Remove TEMP Directory'
    runElevated: true
    runAsSystem: true
    inline: [
      'Remove-Item -Path "C:\\temp" -Recurse -Force | Out-Null; Write-Host "Removed Temp Directory"'
    ]
  }
]
var WindowsUpdate = [
  {
    type: 'WindowsUpdate'
    searchCriteria: 'IsInstalled=0'
    filters: [
      'exclude:$_.Title -like \'*Preview*\''
      'include:$true'
    ]
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
]
var Customizers = union(CreateTempDir, VDOT, Functions, FSLogix, Office, OneDrive, Teams, RemoveTempDir, WindowsUpdate)


resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: ImageTemplateName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}': {
      }
    }
  }
  properties: {
    stagingResourceGroup: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${StagingResourceGroupName}'
    buildTimeoutInMinutes: 300
    vmProfile: {
      userAssignedIdentities: [
        UserAssignedIdentityResourceId
      ]
      vmSize: VirtualMachineSize
      vnetConfig: !empty(SubnetName) ? {
        subnetId: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
      } : null
    }
    source: {
      type: 'PlatformImage'
      publisher: ImagePublisher
      offer: ImageOffer
      sku: ImageSku
      version: ImageVersion
    }
    customize: Customizers
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: ImageDefinitionResourceId
        runOutputName: Timestamp
        artifactTags: {}
        replicationRegions: [
          Location
        ]
        storageAccountType: ImageStorageAccountType
      }
    ]
  }
}
