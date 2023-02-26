targetScope = 'subscription'


@allowed([
  'AvailabilitySet'
  'AvailabilityZones'
  'None'
])
param Availability string = 'None'
param AvailabilitySetNamePrefix string = ''
param AvailabilityZones array = [
  '1'
]
@allowed([
  'ActiveDirectory' // Active Directory Domain Services or Azure Active Directory Domain Services
  'None' // Azure AD Join
  'NoneWithIntune' // Azure AD Join with Intune enrollment
])
param DomainServices string = 'ActiveDirectory'
param HostPoolName string = ''
param HostPoolResourceGroupName string = ''
param KeyVaultResourceId string = ''
param SessionHostCount int = 1
param SessionHostIndex int = 0
param SessionHostOuPath string = ''
param SubnetResourceId string = ''
param Timestamp string = utcNow('yyyyMMddhhmmss')
param VirtualMachineLocation string = deployment().location
param VirtualMachineResourceGroupName string = ''


/*  BEGIN BATCHING VARIABLES */
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var MaxResourcesPerTemplateDeployment = 133 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var DivisionValue = SessionHostCount / MaxResourcesPerTemplateDeployment // This determines if any full batches are required.
var DivisionRemainderValue = SessionHostCount % MaxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var SessionHostBatchCount = DivisionRemainderValue > 0 ? DivisionValue + 1 : DivisionValue // This determines the total number of batches needed, whether full and / or partial.
/*  END BATCHING VARIABLES */

/*  BEGIN AVAILABILITY SET COUNT */
// The following variables are used to determine the number of availability sets.
var MaxAvSetCount = 200 // This is the max number of session hosts that can be deployed in an availability set.
var DivisionAvSetValue = SessionHostCount / MaxAvSetCount // This determines if any full availability sets are required.
var DivisionAvSetRemainderValue = SessionHostCount % MaxAvSetCount // This determines if any partial availability sets are required.
var AvailabilitySetCount = DivisionAvSetRemainderValue > 0 ? DivisionAvSetValue + 1 : DivisionAvSetValue // This determines the total number of availability sets needed, whether full and / or partial.
/*  END AVAILABILITY SET COUNT */


var KeyVaultName = split(KeyVaultResourceId, '/')[8]
var KeyVaultResourceGroupName = split(KeyVaultResourceId, '/')[4]
var KeyVaultSubscriptionId = split(KeyVaultResourceId, '/')[2]


module hostPool 'modules/hostPool.bicep' = {
  name: 'ExistingHostPool_${Timestamp}'
  scope: resourceGroup(HostPoolResourceGroupName)
  params: {
    HostPoolName: HostPoolName
  }
}

module hostPoolRegistrationToken 'modules/hostPoolRegistrationToken.bicep' = {
  name: 'HostPoolRegistrationToken_${Timestamp}'
  scope: resourceGroup(HostPoolResourceGroupName)
  params: {
    HostPoolName: HostPoolName
    HostPoolType: hostPool.outputs.Properties.HostPoolType
    LoadBalancerType: hostPool.outputs.Properties.LoadBalancerType
    Location: hostPool.outputs.Location
    PreferredAppGroupType: hostPool.outputs.Properties.PreferredAppGroupType
    Tags: hostPool.outputs.Tags
  }
}

@batchSize(1)
module sessionHosts 'modules/sessionHosts.bicep' = [for i in range(1, SessionHostBatchCount): {
  name: 'SessionHosts_${i}_${Timestamp}'
  scope: resourceGroup(VirtualMachineResourceGroupName)
  params: {
    Availability: Availability
    AvailabilitySetNamePrefix: AvailabilitySetNamePrefix
    AvailabilitySetCount: AvailabilitySetCount
    AvailabilityZones: AvailabilityZones
    DiskSku: hostPool.outputs.VMTemplate.osDiskType
    DomainName: hostPool.outputs.VMTemplate.domain
    DomainServices: DomainServices
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: HostPoolResourceGroupName
    ImageId : empty(hostPool.outputs.VMTemplate.customImageId) ? '' : hostPool.outputs.VMTemplate.customImageId
    ImageOffer: empty(hostPool.outputs.VMTemplate.galleryImageOffer) ? '' : hostPool.outputs.VMTemplate.galleryImageOffer
    ImagePublisher: empty(hostPool.outputs.VMTemplate.galleryImagePublisher) ? '' : hostPool.outputs.VMTemplate.galleryImagePublisher
    ImageSku: empty(hostPool.outputs.VMTemplate.galleryImageSku) ? '' : hostPool.outputs.VMTemplate.galleryImageSku
    ImageType: hostPool.outputs.VMTemplate.imageType
    ImageVersion: 'latest'
    KeyVaultName: KeyVaultName
    KeyVaultResourceGroupName: KeyVaultResourceGroupName
    KeyVaultSubscriptionId: KeyVaultSubscriptionId
    Location: VirtualMachineLocation
    SessionHostOuPath: SessionHostOuPath
    SessionHostCount: i == SessionHostBatchCount && DivisionRemainderValue > 0 ? DivisionRemainderValue : MaxResourcesPerTemplateDeployment
    SessionHostIndex: i == 1 ? SessionHostIndex : ((i - 1) * MaxResourcesPerTemplateDeployment) + SessionHostIndex
    SubnetResourceId: SubnetResourceId
    Timestamp: Timestamp
    TrustedLaunch: hostPool.outputs.VMTemplate.securityType == 'TrustedLaunch' ? true : false
    VirtualMachineNamePrefix: hostPool.outputs.VMTemplate.namePrefix
    VirtualMachineSize: hostPool.outputs.VMTemplate.vmSize.id
    VirtualMachineTags: hostPool.outputs.Tags
  }
  dependsOn: [
    hostPoolRegistrationToken
  ]
}]
