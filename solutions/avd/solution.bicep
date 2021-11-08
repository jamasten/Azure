targetScope = 'subscription'

@description('Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context')
param CustomRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;'

@description('Enable BitLocker encrytion on the AVD session hosts and management VM if applicable.')
param DiskEncryption bool = false

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
@description('The storage SKU for the AVD session host disks.  Production deployments should use Premium_LRS.')
param DiskSku string = 'Standard_LRS'

param DodStigCompliance bool = false

@secure()
@description('The password of the privileged account to domain join the AVD session hosts to your domain')
param DomainJoinPassword string

@description('The UPN of the privileged account to domain join the AVD session hosts to your domain. This should be an account the resides within the domain you are joining.')
param DomainJoinUserPrincipalName string

@description('The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD')
param DomainName string = 'jasonmasten.com'

@allowed([
  'ActiveDirectory'
  'AzureActiveDirectory'
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to determine the proper solution to domain join the Azure Storage Account.')
param DomainServices string = 'AzureActiveDirectory'

@description('Enable drain mode on sessions hosts during deployment to prevent users from accessing the session hosts.')
param DrainMode bool = false

@description('Choose whether the session host uses an ephemeral disk for the operating system.  Be sure to select a VM SKU that offers a temporary disk that meets your image requirements. Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks')
param EphemeralOsDisk bool = false

@description('Enable FSLogix to manage user profiles for the AVD session hosts.')
param FSLogix bool = true

@allowed([
  'Pooled DepthFirst'
  'Pooled BreadthFirst'
  'Personal Automatic'
  'Personal Direct'
])
@description('These options specify the host pool type and depending on the type provides the load balancing options and assignment types.')
param HostPoolType string = 'Pooled DepthFirst'

@description('Offer for the virtual machine image')
param ImageOffer string = 'office-365'

@description('Publisher for the virtual machine image')
param ImagePublisher string = 'MicrosoftWindowsDesktop'

@description('SKU for the virtual machine image')
param ImageSku string = '21h1-evd-o365pp'

@description('Version for the virtual machine image')
param ImageVersion string = 'latest'

@allowed([
  'AES256'
  'RC4'
])
@description('The Active Directory computer object Kerberos encryption type for the Azure Storage Account.')
param KerberosEncryption string = 'RC4'

@maxValue(730)
@minValue(30)
@description('The retention for the Log Analytics Workspace to setup the AVD Monitoring solution')
param LogAnalyticsWorkspaceRetention int = 30

@allowed([
  'Free'
  'Standard'
  'Premium'
  'PerNode'
  'PerGB2018'
  'Standalone'
  'CapacityReservation'
])
@description('The SKU for the Log Analytics Workspace to setup the AVD Monitoring solution')
param LogAnalyticsWorkspaceSku string = 'PerGB2018'

@description('The maximum number of sessions per AVD session host.')
param MaxSessionLimit int = 2

@allowed([
  'new'
  'existing'
])
@description('Sets whether this is the first deployment of this solution or is a follow up deployment to add new or additional AVD session hosts.')
param newOrExisting string = 'new'

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param OuPath string = 'OU=AADDC ComputersDC=jasonmastenDC=com'

@description('Enable backups to an Azure Recovery Services vault.  For a pooled host pool this will enable backups on the Azure file share.  For a personal host pool this will enable backups on the AVD sessions hosts.')
param RecoveryServices bool = false

@maxLength(10)
@description('Use letters and numbers only.  This suffix is used in conjunction with the resource type prefixes to name most of the Azure resources in this solution.  The only exception is the Storage Account since the value must globally unique and has stricter character requirements.')
param ResourceNameSuffix string = 'avddeu'

@description('Time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours e.g. 9:00 for 9am')
param ScalingBeginPeakTime string = '9:00'

@description('Time when session hosts will scale down and stay off to support low demand; Format 24 hours e.g. 17:00 for 5pm')
param ScalingEndPeakTime string = '17:00'

@description('The number of seconds to wait before automatically signing out users. If set to 0 any session host that has user sessions will be left untouched')
param ScalingLimitSecondsToForceLogOffUser string = '0'

@description('The minimum number of session host VMs to keep running during off-peak hours. The scaling tool will not work if all virtual machines are turned off and the Start VM On Connect solution is not enabled.')
param ScalingMinimumNumberOfRdsh string = '0'

@description('The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours')
param ScalingSessionThresholdPerCPU string = '1'

@description('Time zone off set for host pool location; Format 24 hours e.g. -4:00 for Eastern Daylight Time')
param ScalingTimeDifference string = '-4:00'

@description('Determines whether the Screen Capture Protection feature is enabled.  As of 9/17/21 this is only supported in Azure Cloud. https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection')
param ScreenCaptureProtection bool = false

@description('The Object ID for the Security Principal to assign to the AVD Application Group.  This Security Principal will be assigned the Desktop Virtualization User role on the Application Group.')
param SecurityPrincipalId string = '5c55bf93-86ee-4e1d-a81a-3a78402e6077'

@description('The name for the Security Principal to assign NTFS permissions on the Azure File Share to support FSLogix.  Any value can be input in this field if performing a deployment update or choosing a personal host pool.')
param SecurityPrincipalName string = 'avd_users'

@description('The number of session hosts to deploy in the host pool')
param SessionHostCount int = 1

@description('The session host number to begin with for the deployment. This is important when adding virtual machines to ensure the names do not conflict.')
param SessionHostIndex int = 0

@description('Determines whether the Start VM On Connect feature is enabled. https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect')
param StartVmOnConnect bool = true

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
@description('The SKU for the Azure storage account containing the AVD user profile data.  The selected SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements')
param StorageAccountSku string = 'Standard_LRS'

@description('The subnet for the AVD session hosts.')
param Subnet string = 'Clients'

@description('Key / value pairs of metadata for the Azure resources.')
param Tags object = {
  Owner: 'Jason Masten'
  Purpose: 'POC'
  Environment: 'Development'
}

param TimeStamp string = utcNow('yyyyMMddhhmmss')

@description('The value determines whether the hostpool should receive early AVD updates for testing.')
param ValidationEnvironment bool = false

@description('Virtual network for the AVD sessions hosts')
param VirtualNetwork string = 'vnet-shd-net-d-eu-000'

@description('Virtual network resource group for the AVD sessions hosts')
param VirtualNetworkResourceGroup string = 'rg-shd-net-d-eu-000'

@secure()
@description('Local administrator password for the AVD session hosts')
param VmPassword string

@description('The VM SKU for the AVD session hosts.')
param VmSize string = 'Standard_B2s'

@description('The Local Administrator Username for the Session Hosts')
param VmUsername string

@description('The Object ID for the Windows Virtual Desktop Enterprise Application in Azure AD.  The Object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Azure AD.')
param AvdObjectId string = 'cdcfb416-e2fe-41e2-be12-33813c1cd427'

var AppGroupName = 'dag-${ResourceNameSuffix}'
var AutomationAccountName = 'aa-${ResourceNameSuffix}'
var HostPoolName = 'hp-${ResourceNameSuffix}'
var KeyVaultName = 'kv-${ResourceNameSuffix}'
var Location = deployment().location
var LogAnalyticsWorkspaceName = 'law-${ResourceNameSuffix}'
var LogicAppName = 'la-${ResourceNameSuffix}'
var Netbios = split(DomainName, '.')[0]
var RecoveryServicesVaultName = 'rsv-${ResourceNameSuffix}'
var ResourceGroups = [
    'rg-${ResourceNameSuffix}-infra'
    'rg-${ResourceNameSuffix}-hosts'
]
var RoleAssignmentName = guid(subscription().id, 'WindowsVirtualDesktop')
var RoleDefinitionName = guid(subscription().id, 'StartVmOnConnect')
var StorageAccountName = 'stor${toLower(substring(uniqueString(subscription().id, ResourceGroups[0]), 0, 11))}'
var TimeZones = {
    australiacentral: 'Australian Eastern Standard Time'
    australiacentral2: 'Australian Eastern Standard Time'
    australiaeast: 'Australian Eastern Standard Time'
    australiasoutheast: 'Australian Eastern Standard Time'
    brazilsouth: 'Brasília Time'
    brazilsoutheast: 'Brasília Time'
    canadacentral: 'Eastern Standard Time'
    canadaeast: 'Eastern Standard Time'
    centralindia: 'India Standard Time'
    centralus: 'Central Standard Time'
    chinaeast: 'China Standard Time'
    chinaeast2: 'China Standard Time'
    chinanorth: 'China Standard Time'
    chinanorth2: 'China Standard Time'
    eastasia: 'Hong Kong Time'
    eastus: 'Eastern Standard Time'
    eastus2: 'Eastern Standard Time'
    francecentral: 'Central European Time'
    francesouth: 'Central European Time'
    germanynorth: 'Central European Time'
    germanywestcentral: 'Central European Time'
    japaneast: 'Japan Standard Time'
    japanwest: 'Japan Standard Time'
    jioindiacentral: 'India Standard Time'
    jioindiawest: 'India Standard Time'
    koreacentral: 'Korea Standard Time'
    koreasouth: 'Korea Standard Time'
    northcentralus: 'Central Standard Time'
    northeurope: 'Irish Standard Time'
    norwayeast: 'Central European Time'
    norwaywest: 'Central European Time'
    southafricanorth: 'South Africa Standard Time'
    southafricawest: 'South Africa Standard Time'
    southcentralus: 'Central Standard Time'
    southindia: 'India Standard Time'
    southeastasia: 'Singapore Time'
    swedencentral: 'Central European Time'
    switzerlandnorth: 'Central European Time'
    switzerlandwest: 'Central European Time'
    uaecentral: 'Gulf Standard Time'
    uaenorth: 'Gulf Standard Time'
    uksouth: 'Greenwich Mean Time'
    ukwest: 'Greenwich Mean Time'
    usdodcentral: 'Central Standard Time'
    usdodeast: 'Eastern Standard Time'
    usgovarizona: 'Mountain Standard Time'
    usgoviowa: 'Central Standard Time'
    usgovtexas: 'Central Standard Time'
    usgovvirginia: 'Eastern Standard Time'
    westcentralus: 'Mountain Standard Time'
    westeurope: 'Central European Time'
    westindia: 'India Standard Time'
    westus: 'Pacific Standard Time'
    westus2: 'Pacific Standard Time'
    westus3: 'Mountain Standard Time'
}
var VmName = 'vm${ResourceNameSuffix}'
var VmTemplate = '{\'domain\':\'${DomainName}\',\'galleryImageOffer\':\'${ImageOffer}\',\'galleryImagePublisher\':\'${ImagePublisher}\',\'galleryImageSKU\':\'${ImageSku}\',\'imageType\':\'Gallery\',\'imageUri\':null,\'customImageId\':null,\'namePrefix\':\'${VmName}\',\'osDiskType\':\'${DiskSku}\',\'useManagedDisks\':true,\'vmSize\':{\'id\':\'${VmSize}\',\'cores\':null,\'ram\':null},\'galleryItemId\':\'${ImagePublisher}.${ImageOffer}${ImageSku}\'}'
var WorkspaceName = 'ws-${ResourceNameSuffix}'

resource rgInfra 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroups[0]
  location: Location
  tags: Tags
}

resource rgHosts 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: ResourceGroups[1]
  location: Location
  tags: Tags
}

resource customRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' = if(StartVmOnConnect) {
  name: RoleDefinitionName
  properties: {
    assignableScopes: [
      subscription().id
    ]
    roleName: 'StartVmOnConnect'
    description: 'Allow AVD session hosts to be started when needed.'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/virtualMachines/start/action'
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.Compute/virtualMachines/instanceView/read'
        ]
        notActions: []
      }
    ]
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = if(StartVmOnConnect) {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: customRole.id
    principalId: AvdObjectId
  }
}

module hostPool 'modules/hostPool.bicep' = {
  name: 'hostPool_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    AppGroupName: AppGroupName
    CustomRdpProperty: CustomRdpProperty
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    LogAnalyticsWorkspaceRetention: LogAnalyticsWorkspaceRetention
    LogAnalyticsWorkspaceSku: LogAnalyticsWorkspaceSku
    Location: Location
    MaxSessionLimit: MaxSessionLimit
    newOrExisting: newOrExisting
    SecurityPrincipalId: SecurityPrincipalId
    StartVmOnConnect: StartVmOnConnect
    Tags: Tags
    ValidationEnvironment: ValidationEnvironment
    VmTemplate: VmTemplate
    WorkspaceName: WorkspaceName
  } 
}

module sessionHosts 'modules/sessionHosts.bicep' = {
  name: 'sessionHosts_${TimeStamp}'
  scope: resourceGroup(ResourceGroups[1])
  params: {
    DiskSku: DiskSku
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    EphemeralOsDisk: EphemeralOsDisk
    FSLogix: FSLogix
    HostPoolName: hostPool.outputs.HostPoolName
    HostPoolResourceGroupName: rgInfra.name
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    Location: Location
    LogAnalyticsWorkspaceResourceId: hostPool.outputs.LogAnalyticsWorkspaceResourceId
    OuPath: OuPath
    ResourceNameSuffix: ResourceNameSuffix
    ScreenCaptureProtection: ScreenCaptureProtection
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    StorageAccountName: StorageAccountName
    Subnet: Subnet
    Tags: Tags
    Timestamp: TimeStamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    VmPassword: VmPassword
    VmSize: VmSize
    VmUsername: VmUsername
  }  
}

module fslogix 'modules/fslogix.bicep' = if(split(HostPoolType, ' ')[0] == 'Pooled' && FSLogix) {
  name: 'fslogix_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DomainServices: DomainServices
    HostPoolName: hostPool.outputs.HostPoolName
    KerberosEncryptionType: KerberosEncryption
    Location: Location
    Netbios: Netbios
    OuPath: OuPath
    ResourceNameSuffix: ResourceNameSuffix
    SecurityPrincipalId: SecurityPrincipalId
    SecurityPrincipalName: SecurityPrincipalName
    StorageAccountName: StorageAccountName
    StorageAccountSku: StorageAccountSku
    Subnet: Subnet
    Tags: Tags
    Timestamp: TimeStamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
}

module backup 'modules/backup.bicep' = if(RecoveryServices) {
  name: 'backup_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    HostPoolName: hostPool.outputs.HostPoolName
    HostPoolType: HostPoolType
    Location: Location
    RecoveryServicesVaultName: RecoveryServicesVaultName
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    StorageAccountName: fslogix.outputs.StorageAccountName
    Tags: Tags
    TimeZone: TimeZones[Location]
    VmName: sessionHosts.outputs.VmName
    VmResourceGroupName: ResourceGroups[1]
  } 
}

module bitLocker 'modules/bitLocker.bicep' = if(DiskEncryption) {
  name: 'bitLocker_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    FSLogix: FSLogix
    KeyVaultName: KeyVaultName
    Location: Location
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    SessionHostResourceGroupName: ResourceGroups[1]
    Timestamp: TimeStamp
    VmName: sessionHosts.outputs.VmName
  } 
}

module stig 'modules/stig.bicep' = if(DodStigCompliance) {
  name: 'stig_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    AutomationAccountName: AutomationAccountName
    Location: Location
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    Timestamp: TimeStamp
    VmName: sessionHosts.outputs.VmName
    VmResourceGroupName: ResourceGroups[1]
  } 
}

module scale 'modules/scale.bicep' = if(split(HostPoolType, ' ')[0] == 'Pooled') {
  name: 'scale_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: ScalingBeginPeakTime
    EndPeakTime: ScalingEndPeakTime
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: rgInfra.name
    LimitSecondsToForceLogOffUser: ScalingLimitSecondsToForceLogOffUser
    Location: Location
    LogAnalyticsWorkspaceResourceId: hostPool.outputs.LogAnalyticsWorkspaceResourceId
    LogicAppName: LogicAppName
    MinimumNumberOfRdsh: ScalingMinimumNumberOfRdsh
    SessionHostsResourceGroupName: ResourceGroups[1]
    SessionThresholdPerCPU: ScalingSessionThresholdPerCPU
    TimeDifference: ScalingTimeDifference
  }
  dependsOn: [
    sessionHosts
    fslogix
    bitLocker
  ]
}

module drainMode 'modules/drainMode.bicep' = if(split(HostPoolType, ' ')[0] == 'Pooled' && DrainMode) {
  name: 'drainMode_${TimeStamp}'
  scope: resourceGroup(rgInfra.name)
  params: {
    HostPoolName: hostPool.outputs.HostPoolName
    HostPoolResourceGroupName: rgInfra.name
    Location: Location
    Timestamp: TimeStamp
  }
  dependsOn: [
    sessionHosts
    fslogix
  ]
}
