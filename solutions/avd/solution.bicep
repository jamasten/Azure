targetScope = 'subscription'

@description('The URL prefix for linked resources.')
param ArtifactsLocation string = 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/'

@allowed([
  'AvailabilitySet'
  'AvailabilityZones'
  'None'
])
@description('Set the desired availability / SLA with a pooled host pool.  Choose "None" if deploying a personal host pool.')
param Availability string = 'None'

@description('Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context')
param CustomRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;'

@description('Enable BitLocker encrytion on the AVD session hosts and management VM.')
param DiskEncryption bool = false

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
@description('The storage SKU for the AVD session host disks.  Production deployments should use Premium_LRS.')
param DiskSku string = 'Standard_LRS'

@description('Deploys an Automation Account and uses State Configuration to deploy and monitor DSC compliance.  PowerSTIG is used for the STIG configurations that adhere to DISAs STIG compliance.')
param DisaStigCompliance bool = false

@description('The IP address for the first Forwarder on the DNS Server.')
param DnsServerForwarderIPAddress01 string = ''

@description('The IP address for the second Forwarder on the DNS Server.')
param DnsServerForwarderIPAddress02 string = ''

@allowed([
  'Standard_D2s_v4'
  'Standard_D4s_v4'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
])
@description('The size of the virtual machine for the DNS server.')
param DnsServerSize string = 'Standard_D2s_v4'

@secure()
@description('The password of the privileged account to domain join the AVD session hosts to your domain')
param DomainJoinPassword string

@description('The UPN of the privileged account to domain join the AVD session hosts to your domain. This should be an account the resides within the domain you are joining.')
param DomainJoinUserPrincipalName string

@description('The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD')
param DomainName string = 'jasonmasten.com'

@allowed([
  'ActiveDirectory' // Active Directory Domain Services
  'AzureActiveDirectory' // Azure Active Directory Domain Services
  'None' // Azure AD Join
  'NoneWithIntune' // Azure AD Join with Intune enrollment
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to determine the proper solution to domain join the Azure Storage Account.')
param DomainServices string = 'AzureActiveDirectory'

@description('Enable drain mode on sessions hosts during deployment to prevent users from accessing the session hosts.')
param DrainMode bool = false

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared
  't' // Test
])
@description('The target environment for the solution.')
param Environment string = 'd'


@description('Choose whether the session host uses an ephemeral disk for the operating system.  Be sure to select a VM SKU that offers a temporary disk that meets your image requirements. Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks')
param EphemeralOsDisk bool = false

@description('The file share size(s) in GB for the Fslogix storage solution.')
param FslogixShareSizeInGB int

@allowed([
  'CloudCache' // FSLogix Cloud Cache
  'ProfileContainer' // FSLogix Profile Container
  'ProfileOfficeContainer' // FSLogix Profile & Office Container
])
param FslogixSolution string = 'ProfileContainer'

@allowed([
  'AzureNetAppFiles Premium' // ANF with the Premium SKU, 450,000 IOPS
  'AzureNetAppFiles Standard' // ANF with the Standard SKU, 320,000 IOPS
  'AzureNetAppFiles Ultra' // ANF with the Ultra SKU, 450,000 IOPS
  'AzureStorageAccount Premium PublicEndpoint' // Azure Files Premium with the default public endpoint, 100,000 IOPS
  'AzureStorageAccount Premium PrivateEndpoint' // Azure Files Premium with a Private Endpoint, 100,000 IOPS
  'AzureStorageAccount Premium ServiceEndpoint' // Azure Files Premium with a Service Endpoint, 100,000 IOPs
  'AzureStorageAccount Standard PublicEndpoint' // Azure Files Standard with the Large File Share option and the default public endpoint, 20,000 IOPS
  'AzureStorageAccount Standard PrivateEndpoint' // Azure Files Standard with the Large File Share option and a Private Endpoint, 20,000 IOPS
  'AzureStorageAccount Standard ServiceEndpoint' // Azure Files Standard with the Large File Share option and a Service Endpoint, 20,000 IOPS
  'None'
])
@description('Enable an Fslogix storage option to manage user profiles for the AVD session hosts. The selected service & SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements')
param FslogixStorage string = 'AzureStorageAccount Standard PublicEndpoint'

@allowed([
  'Pooled DepthFirst'
  'Pooled BreadthFirst'
  'Personal Automatic'
  'Personal Direct'
])
@description('These options specify the host pool type and depending on the type provides the load balancing options and assignment types.')
param HostPoolType string = 'Pooled DepthFirst'

@description('Choose whether to enable the Hybrid Use Benefit on the DNS forwarder to support Private Endpoints.  Leave the default value if you are not deploying an Azure Storage Account with a Private Endpoint.')
param HybridUseBenefit bool = false

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

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
@description('The Active Directory computer object Kerberos encryption type for the Azure Storage Account or Azure NetApp Files Account.')
param KerberosEncryption string = 'RC4'

param Location string = deployment().location

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

@description('Deploys the required monitoring resources to enable AVD Insights.')
param Monitoring bool = true

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param OuPath string

@description('Enables the RDP Short Path feature: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath')
param RdpShortPath bool = false

@description('Enable backups to an Azure Recovery Services vault.  For a pooled host pool this will enable backups on the Azure file share.  For a personal host pool this will enable backups on the AVD sessions hosts.')
param RecoveryServices bool = false

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
param ScalingTimeDifference string = '-5:00'

@description('Determines whether the Screen Capture Protection feature is enabled.  As of 9/17/21 this is only supported in Azure Cloud. https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection')
param ScreenCaptureProtection bool = false

@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param SasToken string = ''

@description('An array of Object IDs for the Security Principals to assign to the AVD Application Group and FSLogix Storage.')
param SecurityPrincipalObjectIds array

@description('The name for the Security Principal to assign NTFS permissions on the Azure File Share to support Fslogix.  Any value can be input in this field if performing a deployment update or choosing a personal host pool.')
param SecurityPrincipalNames array

@description('The number of session hosts to deploy in the host pool.  The default values will allow you deploy 250 VMs using 4 nested deployments.  These integers may be modified to create a smaller deployment in a shard.')
param SessionHostCount int = 2

@description('The session host number to begin with for the deployment. This is important when adding virtual machines to ensure the names do not conflict.')
param SessionHostIndex int = 0

@description('The stamp index specifies the AVD stamp within an Azure environment.')
param StampIndex int = 0

@description('Determines whether the Start VM On Connect feature is enabled. https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect')
param StartVmOnConnect bool = true

@minValue(1)
@description('The Storage Count allows the deployment of one or more storage resources within an AVD stamp to shard for extra capacity. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param StorageCount int = 1

@description('The Storage Index allows the deployment of one or more storage resources within an AVD stamp to shard for extra capacity. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param StorageIndex int = 0

@description('The subnet for the AVD session hosts.')
param Subnet string = 'Clients'

@description('Key / value pairs of metadata for the Azure resources.')
param Tags object = {
  Owner: 'Jason Masten'
  Purpose: 'POC'
  Environment: 'Development'
}

param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('The value determines whether the hostpool should receive early AVD updates for testing.')
param ValidationEnvironment bool = false

@description('Virtual network for the AVD sessions hosts')
param VirtualNetwork string = 'vnet-shd-net-d-eu'

@description('Virtual network resource group for the AVD sessions hosts')
param VirtualNetworkResourceGroup string = 'rg-shd-net-d-eu'

@secure()
@description('Local administrator password for the AVD session hosts')
param VmPassword string

@description('The VM SKU for the AVD session hosts.')
param VmSize string = 'Standard_D4s_v4'

@description('The Local Administrator Username for the Session Hosts')
param VmUsername string


/*  BEGIN BATCHING SESSION HOSTS */
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var MaxResourcesPerTemplateDeployment = 79 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var DivisionValue = SessionHostCount / MaxResourcesPerTemplateDeployment // This determines if any full batches are required.
var DivisionRemainderValue = SessionHostCount % MaxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var SessionHostBatchCount = DivisionRemainderValue > 0 ? DivisionValue + 1 : DivisionValue // This determines the total number of batches needed, whether full and / or partial.
/*  END BATCHING SESSION HOSTS */


/*  BEGIN AVAILABILITY SET COUNT */
// The following variables are used to determine the number of availability sets.
var MaxAvSetCount = 200 // This is the max number of session hosts that can be deployed in an availability set.
var DivisionAvSetValue = SessionHostCount / MaxAvSetCount // This determines if any full availability sets are required.
var DivisionAvSetRemainderValue = SessionHostCount % MaxAvSetCount // This determines if any partial availability sets are required.
var AvailabilitySetCount = DivisionAvSetRemainderValue > 0 ? DivisionAvSetValue + 1 : DivisionAvSetValue // This determines the total number of availability sets needed, whether full and / or partial.
/*  END AVAILABILITY SET COUNT */


var AppGroupName = 'dag-${NamingStandard}'
var AvailabilitySetPrefix = 'as-${NamingStandard}'
var AutomationAccountName = 'aa-${NamingStandard}'
var DnsServerForwarderIPAddresses = empty(DnsServerForwarderIPAddress02) ? [
  DnsServerForwarderIPAddress01
] : [
  DnsServerForwarderIPAddress01
  DnsServerForwarderIPAddress02
]
var ConfigurationName = 'Windows10'
var ConfigurationsUri = '${ArtifactsLocation}configurations/'
var FileShareNames = {
  ProfileContainer: [
    'profilecontainers'
  ]
  ProfileOfficeContainer: [
    'officecontainers'
    'profilecontainers'
  ]
  CloudCache: [
    'cloudcache'
  ]
}
var FileShares = FileShareNames[FslogixSolution]
var Fslogix = FslogixStorage == 'None' || contains(DomainServices, 'None') ? false : true
var HostPoolName = 'hp-${NamingStandard}'
var KeyVaultName = 'kv-${NamingStandard}'
var LocationShortName = LocationShortNames[Location]
var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne'
  norwayeast: 'ne2'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southeastasia: 'sa'
  southindia: 'si'
  swedencentral: 'sc'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'ia'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var LogAnalyticsWorkspaceName = 'law-${NamingStandard}'
var LogicAppPrefix = 'la-${NamingStandard}'
var ManagedIdentityName = 'uami-${NamingStandard}'
var ManagementVmName = '${VmName}mgt'
var NamingStandard = '${Identifier}-${Environment}-${LocationShortName}-${StampIndexFull}'
var NetAppAccountName = 'naa-${NamingStandard}'
var NetAppCapacityPoolName = 'nacp-${NamingStandard}'
var Netbios = split(DomainName, '.')[0]
var NetworkSecurityGroupName = 'nsg-${NamingStandard}'
var PooledHostPool = split(HostPoolType, ' ')[0] == 'Pooled' ? true : false
var PrivateDnsZoneName = 'privatelink.file.${StorageSuffix}'
var PrivateEndpoint = contains(FslogixStorage, 'PrivateEndpoint') ? true : false
var RecoveryServicesVaultName = 'rsv-${NamingStandard}'
var ResourceGroups = [
  'rg-${NamingStandard}-deployment'  
  'rg-${NamingStandard}-hosts'
  'rg-${NamingStandard}-management'
  'rg-${NamingStandard}-storage'
]
var RoleDefinitionIds = {
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  desktopVirtualizationSessionHostOperator: '2ad6aaab-ead9-4eaa-8ac5-da422f562408'
  networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  storageFileDataSMBShareContributor: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
  virtualMachineUserLogin: 'fb879df8-f326-4884-b1cf-06f3ad86be52'
}
var ScriptsUri = '${ArtifactsLocation}scripts/'
var StampIndexFull = padLeft(StampIndex, 2, '0')
var StorageAccountPrefix = 'st${Identifier}${Environment}${LocationShortName}${StampIndexFull}'
var StorageSolution = split(FslogixStorage, ' ')[0]
var StorageSku = FslogixStorage == 'None' ? 'None' : split(FslogixStorage, ' ')[1]
var StorageSuffix = environment().suffixes.storage
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
var VmName = 'vm${Identifier}${Environment}${LocationShortName}${StampIndexFull}'
var VmTemplate = '{"domain":"${DomainName}","galleryImageOffer":"${ImageOffer}","galleryImagePublisher":"${ImagePublisher}","galleryImageSKU":"${ImageSku}","imageType":"Gallery","imageUri":null,"customImageId":null,"namePrefix":"${VmName}","osDiskType":"${DiskSku}","useManagedDisks":true,"vmSize":{"id":"${VmSize}","cores":null,"ram":null},"galleryItemId":"${ImagePublisher}.${ImageOffer}${ImageSku}"}'
var WorkspaceName = 'ws-${NamingStandard}'


// Resource Groups needed for the solution
resource resourceGroups 'Microsoft.Resources/resourceGroups@2020-10-01' = [for i in range(0, length(ResourceGroups)): {
  name: ResourceGroups[i]
  location: Location
  tags: Tags
}]

// User Assigned Managed Identity
// This resource is needed to run several deployment scripts
module managedIdentity 'modules/managedIdentity/managedIdentity.bicep' = {
  name: 'managedIdentity_${Timestamp}'
  params: {
    DrainMode: DrainMode
    FslogixStorage: FslogixStorage
    Location: Location
    ManagedIdentityName: ManagedIdentityName
    ResourceGroups: ResourceGroups
    RoleDefinitionIds: RoleDefinitionIds
    Timestamp: Timestamp
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
  }
  dependsOn: [
    resourceGroups
  ]
}

// Validation Deployment Script
// This module validates the selected parameter values and collects required data
module validation 'modules/validation.bicep' = {
  name: 'Validation_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    Availability: Availability
    DiskEncryption: DiskEncryption
    DiskSku: DiskSku
    DomainName: DomainName
    DomainServices: DomainServices
    EphemeralOsDisk: EphemeralOsDisk
    FSLogixStorage: FslogixStorage
    ImageSku: ImageSku
    KerberosEncryption: KerberosEncryption
    Location: Location
    ManagedIdentityResourceId: managedIdentity.outputs.resourceIdentifier
    NamingStandard: NamingStandard
    SasToken: SasToken
    ScriptsUri: ScriptsUri    
    SecurityPrincipalIds: SecurityPrincipalObjectIds
    SecurityPrincipalNames: SecurityPrincipalNames
    SessionHostCount: SessionHostCount
    SessionHostIndex: SessionHostIndex
    StorageCount: StorageCount
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmSize: VmSize
  }
  dependsOn: [
    resourceGroups
    managedIdentity
  ]
}

module startVmOnConnect 'modules/startVmOnConnect.bicep' = if(StartVmOnConnect) {
  name: 'StartVmOnConnect_${Timestamp}'
  params: {
    PrincipalId: validation.outputs.avdObjectId
  }
}

module automationAccount 'modules/automationAccount.bicep' = if(PooledHostPool || DisaStigCompliance) {
  name: 'AutomationAccount_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    AutomationAccountName: AutomationAccountName
    Location: Location
  }
  dependsOn: [
    resourceGroups
  ]
}

// AVD Management Resources
// This module deploys the host pool, desktop application group, & workspace
module hostPool 'modules/hostPool.bicep' = {
  name: 'hostPool_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    AppGroupName: AppGroupName
    CustomRdpProperty: CustomRdpProperty
    DomainServices: DomainServices
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    Location: Location
    MaxSessionLimit: MaxSessionLimit
    SecurityPrincipalIds: SecurityPrincipalObjectIds
    StartVmOnConnect: StartVmOnConnect
    Tags: Tags
    ValidationEnvironment: ValidationEnvironment
    VmTemplate: VmTemplate
    WorkspaceName: WorkspaceName
  }
  dependsOn: [
    resourceGroups
  ]
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with Windows Events & Windows Performance Counters plus diagnostic settings on the required resources 
module monitoring 'modules/monitoring.bicep' = if(Monitoring) {
  name: 'monitoring_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    AutomationAccountName: AutomationAccountName
    HostPoolName: HostPoolName
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    LogAnalyticsWorkspaceRetention: LogAnalyticsWorkspaceRetention
    LogAnalyticsWorkspaceSku: LogAnalyticsWorkspaceSku
    Location: Location
    PooledHostPool: PooledHostPool
    Tags: Tags
    WorkspaceName: WorkspaceName
  }
  dependsOn: [
    resourceGroups
    hostPool
  ]
}

module bitLocker 'modules/bitLocker.bicep' = if(DiskEncryption) {
  name: 'bitLocker_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    KeyVaultName: KeyVaultName
    Location: Location
    //ManagedIdentityName: managedIdentity.name
    ManagedIdentityPrincipalId: managedIdentity.outputs.principalId
    ManagedIdentityResourceId: managedIdentity.outputs.resourceIdentifier
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    Timestamp: Timestamp
  }
}

module stig 'modules/stig.bicep' = if(DisaStigCompliance) {
  name: 'stig_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    AutomationAccountName: AutomationAccountName
    ConfigurationName: ConfigurationName
    ConfigurationsUri: ConfigurationsUri
    Location: Location
    Timestamp: Timestamp
  }
  dependsOn: [
    resourceGroups
    automationAccount
  ]
}

module fslogix 'modules/fslogix/fslogix.bicep' = if(Fslogix) {
  name: 'FSLogix_${Timestamp}'
  params: {
    ActiveDirectoryConnection: validation.outputs.anfActiveDirectory
    ConfigurationsUri: ConfigurationsUri
    DelegatedSubnetId: validation.outputs.subnetId
    DiskEncryption: DiskEncryption
    DnsServerForwarderIPAddresses: DnsServerForwarderIPAddresses
    DnsServers: validation.outputs.dnsServers
    DnsServerSize: DnsServerSize
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DomainServices: DomainServices
    Environment: Environment
    FileShares: FileShares
    FslogixShareSizeInGB: FslogixShareSizeInGB
    FslogixStorage: FslogixStorage
    HostPoolName: HostPoolName
    HybridUseBenefit: HybridUseBenefit
    Identifier: Identifier
    KerberosEncryption: KerberosEncryption
    KeyVaultName: KeyVaultName
    Location: Location
    LocationShortName: LocationShortName
    ManagedIdentityResourceId: managedIdentity.outputs.resourceIdentifier
    ManagementVmName: ManagementVmName
    NamingStandard: NamingStandard
    NetAppAccountName: NetAppAccountName
    NetAppCapacityPoolName: NetAppCapacityPoolName
    Netbios: Netbios
    OuPath: OuPath
    PrivateDnsZoneName: PrivateDnsZoneName
    PrivateEndpoint: PrivateEndpoint
    ResourceGroups: ResourceGroups
    RoleDefinitionIds: RoleDefinitionIds
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    SecurityPrincipalIds: SecurityPrincipalObjectIds
    SecurityPrincipalNames: SecurityPrincipalNames
    SmbServerLocation: LocationShortName
    StampIndexFull: StampIndexFull
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageSku: StorageSku
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
  dependsOn: [
    bitLocker
    managedIdentity
    stig
  ]
}

module sessionHosts 'modules/sessionHosts/sessionHosts.bicep' = {
  name: 'SessionHosts_${Timestamp}'
  scope: resourceGroup(ResourceGroups[1]) // Hosts Resource Group
  params: {
    AcceleratedNetworking: validation.outputs.acceleratedNetworking
    AutomationAccountName: AutomationAccountName
    Availability: Availability
    AvailabilitySetCount: AvailabilitySetCount
    AvailabilitySetPrefix: AvailabilitySetPrefix
    ConfigurationName: ConfigurationName
    DisaStigCompliance: DisaStigCompliance
    DiskEncryption: DiskEncryption
    DiskSku: DiskSku
    DivisionRemainderValue: DivisionRemainderValue
    DomainJoinPassword: DomainJoinPassword
    DomainJoinUserPrincipalName: DomainJoinUserPrincipalName
    DomainName: DomainName
    DomainServices: DomainServices
    EphemeralOsDisk: validation.outputs.ephemeralOsDisk
    FileShares: FileShares
    Fslogix: Fslogix
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    ImageOffer: ImageOffer
    ImagePublisher: ImagePublisher
    ImageSku: ImageSku
    ImageVersion: ImageVersion
    KeyVaultName: KeyVaultName
    Location: Location
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
    MaxResourcesPerTemplateDeployment: MaxResourcesPerTemplateDeployment
    Monitoring: Monitoring
    NamingStandard: NamingStandard
    NetAppFileShare: StorageSolution == 'AzureNetAppFiles' ? fslogix.outputs.netAppShare : 'None'
    NetworkSecurityGroupName: NetworkSecurityGroupName
    OuPath: OuPath
    PooledHostPool: PooledHostPool
    RdpShortPath: RdpShortPath
    ResourceGroups: ResourceGroups
    RoleDefinitionIds: RoleDefinitionIds
    SasToken: SasToken
    ScreenCaptureProtection: ScreenCaptureProtection
    ScriptsUri: ScriptsUri
    SecurityPrincipalObjectIds: SecurityPrincipalObjectIds
    SessionHostBatchCount: SessionHostBatchCount
    SessionHostIndex: SessionHostIndex
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex 
    StorageSolution: StorageSolution
    StorageSuffix: StorageSuffix
    Subnet: Subnet
    Tags: Tags
    Timestamp: Timestamp
    VirtualNetwork: VirtualNetwork
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VmName: VmName
    VmPassword: VmPassword
    VmSize: VmSize
    VmUsername: VmUsername
  }
  dependsOn: [
    resourceGroups
    monitoring
    bitLocker
    stig
  ]
}

module backup 'modules/backup.bicep' = if(RecoveryServices) {
  name: 'backup_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    DivisionRemainderValue: DivisionRemainderValue
    HostPoolName: HostPoolName
    HostPoolType: HostPoolType
    Location: Location
    MaxResourcesPerTemplateDeployment: MaxResourcesPerTemplateDeployment
    RecoveryServicesVaultName: RecoveryServicesVaultName
    SessionHostBatchCount: SessionHostBatchCount
    SessionHostIndex: SessionHostIndex
    StorageAccountName: StorageAccountPrefix
    Tags: Tags
    Timestamp: Timestamp
    TimeZone: TimeZones[Location]
    VmName: VmName
    VmResourceGroupName: ResourceGroups[1]
  }
  dependsOn: [
    sessionHosts
    fslogix
  ]
}

// Deploys scaling for the session hosts and Azure Files Premium, if applicable
module scale 'modules/scale.bicep' = if(PooledHostPool) {
  name: 'scale_${Timestamp}'
  scope: resourceGroup(ResourceGroups[2]) // Management Resource Group
  params: {
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: ScalingBeginPeakTime
    EndPeakTime: ScalingEndPeakTime
    FslogixStorage: FslogixStorage
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroups[2] // Management Resource Group
    LimitSecondsToForceLogOffUser: ScalingLimitSecondsToForceLogOffUser
    Location: Location
    LogicAppPrefix: LogicAppPrefix
    MinimumNumberOfRdsh: ScalingMinimumNumberOfRdsh
    SasToken: SasToken
    ScriptsUri: ScriptsUri    
    SessionHostsResourceGroupName: ResourceGroups[1] // Hosts Resource Group
    SessionThresholdPerCPU: ScalingSessionThresholdPerCPU
    StorageAccountPrefix: StorageAccountPrefix
    StorageResourceGroupName: ResourceGroups[3] // Hosts Resource Group
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    TimeDifference: ScalingTimeDifference
  }
  dependsOn: [
    automationAccount
    backup
    sessionHosts
  ]
}

// Enables drain mode on the session hosts so users cannot login
module drainMode 'modules/drainMode.bicep' = if(DrainMode) {
  name: 'drainMode_${Timestamp}'
  scope: resourceGroup(ResourceGroups[0]) // Deployment Resource Group
  params: {
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: ResourceGroups[2] // Management Resource Group
    Location: Location
    ManagedIdentityResourceId: managedIdentity.outputs.resourceIdentifier
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    Tags: Tags
    Timestamp: Timestamp
  }
  dependsOn: [
    sessionHosts
  ]
}
