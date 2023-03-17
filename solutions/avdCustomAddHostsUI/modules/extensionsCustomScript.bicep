param AmdVmSize bool
param DeployAip bool
param DeployAppMaskingRules bool
param DeployProjectVisio bool
param DisaStigCompliance bool
param DomainName string
param HostPoolName string
param HostPoolResourceGroupName string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param Location string
param NvidiaVmSize bool
param ScreenCaptureProtection bool
@secure()
param ScriptContainerSasToken string
param ScriptContainerUri string
param SessionHostCount int
param SessionHostIndex int
param Tags object
param Timestamp string
param VmName string


resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VmName}${padLeft((i + SessionHostIndex), 4, '0')}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptContainerUri}AppMasking.zip${ScriptContainerSasToken}'
        '${ScriptContainerUri}Icons.zip${ScriptContainerSasToken}'
        '${ScriptContainerUri}NetBanner.msi${ScriptContainerSasToken}'
        '${ScriptContainerUri}Office.zip${ScriptContainerSasToken}'
        '${ScriptContainerUri}Set-SessionHostConfiguration.ps1${ScriptContainerSasToken}'
        '${ScriptContainerUri}VDOT.zip${ScriptContainerSasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Set-SessionHostConfiguration.ps1 -AmdVmSize ${AmdVmSize} -DeployAip ${DeployAip} -DeployAppMaskingRules ${DeployAppMaskingRules} -DeployProjectVisio ${DeployProjectVisio} -DisaStigCompliance ${DisaStigCompliance} -DomainName ${DomainName} -Environment ${environment().name} -HostPoolName ${HostPoolName} -HostPoolRegistrationToken "${reference(resourceId(HostPoolResourceGroupName, 'Microsoft.DesktopVirtualization/hostpools', HostPoolName), '2019-12-10-preview').registrationInfo.token}" -ImageOffer ${ImageOffer} -ImagePublisher ${ImagePublisher} -ImageSku ${ImageSku} -NvidiaVmSize ${NvidiaVmSize} -ScreenCaptureProtection ${ScreenCaptureProtection}'
    }
  }
}]
