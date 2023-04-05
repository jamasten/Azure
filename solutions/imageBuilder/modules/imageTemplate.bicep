param DeployFSLogix bool
param DeployOffice bool
param DeployOneDrive bool
param DeployTeams bool
param DeployVirtualDesktopOptimizationTool bool
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
      'New-Item -Path "C:\\" -Name "temp" -ItemType "Directory" -Force'
    ]
  }
]

var FSLogixType = contains(ImageSku, 'avd') ? [
  {
    type: 'PowerShell'
    name: 'Uninstall FSLogix'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}fslogix.ps1'
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
    scriptUri: '${StorageUri}fslogix.ps1'
  }
  {
    type: 'WindowsRestart'
    restartTimeout: '5m'
  }
] : [
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
var Office = DeployOffice ? [
  {
    type: 'PowerShell'
    name: 'Install Microsoft Office 365'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}o365.ps1'
  }
] : []
var OneDrive = DeployOneDrive ? [
  {
    type: 'File'
    name: 'Tenant ID'
    sourceUri: '${StorageUri}tenantId.txt'
    destination: 'C:\\temp\\tenantId.txt'
  }
  {
    type: 'PowerShell'
    name: 'Install One Drive'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}onedrive.ps1'
  }
] : []
var Teams = DeployTeams ? [
  {
    type: 'PowerShell'
    name: 'Install Teams'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}teams.ps1'
  }
] : []
var VDOT = DeployVirtualDesktopOptimizationTool ? [
  {
    type: 'PowerShell'
    name: 'Download & Run the Virtual Desktop Optimization Tool'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}vdot.ps1'
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
      'Remove-Item -Path "C:\\temp" -Recurse -Force'
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
var Customizers = union(CreateTempDir, VDOT, FSLogix, Office, OneDrive, Teams, RemoveTempDir, WindowsUpdate)


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
