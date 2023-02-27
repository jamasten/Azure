param DeployProjectVisio bool
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
      'New-Item -Path "C:\\" -Name "temp" -ItemType "Directory"'
    ]
  }
]
var ProjectOffice = DeployProjectVisio ? [
  {
    type: 'File'
    name: 'Download the Office Deployment Tool with custom XML'
    sourceUri: '${StorageUri}office.zip'
    destination: 'C:\\temp\\office.zip'
    sha256Checksum: toLower('37d222cdf71e9519872e6c24fbc7c30fbd230419710c5a1d7ef3c227c261e41b') // value must be lowercase
  }
  {
    type: 'PowerShell'
    name: 'Install Microsoft Project & Visio'
    runElevated: true
    runAsSystem: true
    scriptUri: '${StorageUri}projectVisio.ps1'
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
    restartCheckCommand: 'Write-Host "Restarting Windows after running the Virtual Desktop Optimization Tool"'
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
    restartCheckCommand: 'Write-Host "Restarting Windows after running the Virtual Desktop Optimization Tool"'
    restartTimeout: '5m'
  }
]
var Customizers = union(CreateTempDir, ProjectOffice, VDOT, RemoveTempDir, WindowsUpdate)


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
