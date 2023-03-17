# Azure Virtual Desktop - Custom Add Session Hosts UI

This solution will deploy a Template Spec with a custom UI definition to simplify session host deployments.

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

## Deployment Options

### PowerShell

````powershell
New-AvdTemplateSpec.ps1 `
    -Availability '<Availability Option>' `
    -AvailabilitySetNamePrefix '<Availability Set Name Prefix>' `
    -AvailabilityZones @('1') `
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
