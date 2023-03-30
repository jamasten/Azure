# Azure Virtual Desktop - Custom Add Session Hosts UI

This solution will deploy a Template Spec with a custom UI definition to simplify session host deployments for AVD host pools. When a host pool is deployed in the portal, it includes a "VMTemplate" property. This property is used to determine many details for the deployment.

If a host pool was created using code and does not include a value for the "VMTemplate" property, it can be easily created by manually adding a session host to your host pool in the Azure Portal. Use the following PowerShell command to validate the value of the VMTemplate property on your host pool:

```powershell
Get-AzWvdHostPool `
    -Name '<Host Pool Name>' `
    -ResourceGroupName '<Resource Group Name>' `
    | Select-Object -ExpandProperty 'vmtemplate'
```

## Resources

The following resources are deployed with this solution:

- Template Spec with a custom UI Definition

## Prerequisites

To deploy this solution, the following items need to be configured before running the script:

- Key Vault with Secrets using the following names:
  - "DomainPassword" - password to domain join the session hosts
  - "DomainUserPrincipalName" - user principal name to domain join the session hosts
  - "LocalAdminPassword" - password for the local administrator account
  - "LocalAdminUsername" - username for the local administrator account
- Outbound network connectivity to download the following resources:
  - Script for Custom Script Extension
  - AVD Agents

> **NOTE:** The domain credentials are only required when domain joining your AVD session hosts.

## Deployment Options

### PowerShell

````powershell
New-AvdTemplateSpec.ps1 `
    -Availability '<Availability Option>' `
    -AvailabilitySetNamePrefix '<Availability Set Name Prefix>' `
    -AvailabilityZones @('1') `
    -DiskEncryptionSetResourceId '<Resource ID for the Disk Encryption Set>' `
    -DomainServices '<Domain Services Option>' `
    -Environment '<Azure Environment Name>' `
    -HostPoolName '<Name of the AVD Host Pool>' `
    -HostPoolResourceGroupName '<Name of the Resource Group for the AVD Host Pool>' `
    -KeyVaultResourceId '<Resource ID for the Key Vault>' `
    -SessionHostOuPath '<Distinguished Name for the Organizational Unit in AD DS>' `
    -SubnetResourceId '<Resource ID for the Subnet>' `
    -TemplateSpecName '<Name of the Template Spec>' `
    -TemplateSpecVersion '<Semantic Versioning Number>' `
    -TenantId '<Tenant ID in Azure AD>' `
    -VirtualMachineResourceGroupName '<Name of the Resource Group for the Virtual Machines>'
````

> **NOTE:** Some of the parameters in the above script are only required in specific scenarios.  Be sure to review the script to determine which parameters are mandatory.
