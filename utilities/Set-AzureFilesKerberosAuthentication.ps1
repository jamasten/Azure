<#
MIT License

Copyright (c) 2022 Jason Masten

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

.SYNOPSIS
Domain joins an Azure Storage Account
.DESCRIPTION
This script will add a storage account to Active Directory Domain Services as a computer object to support kerberos authentication.
.PARAMETER Environment
The name of the Azure environment.
.PARAMETER KerberosEncryptionType
The type of kerberos encrpytion used on the session hosts, the storage account, and domain controllers.
.PARAMETER OuPath
The distinguished name of the organizational unit in Active Directoy Domain Services.
.PARAMETER StorageAccountName
The name of the Azure Storage Account.
.PARAMETER StorageAccountResourceGroupName
The Resource Group name of the Azure Storage Account.
.PARAMETER SubscriptionId
The ID of the Azure Subscription.
.PARAMETER TenantId
The ID of the Azure Active Directory tenant.
.NOTES
  Version:              1.0
  Author:               Jason Masten
  Creation Date:        2023-02-16
  Last Modified Date:   2023-02-16
.EXAMPLE
.\Set-AzureFilesKerberosAuthentication.ps1 `
    -Environment 'AzureCloud' `
    -KerberosEncryptionType 'RC4' `
    -OuPath 'OU=AVD,DC=Fabrikam,DC=COM' `
    -StorageAccountName 'saavdpeus' `
    -StorageAccountResourceGroupName 'rg-avd-p-eus' `
    -SubscriptionId '00000000-0000-0000-0000-000000000000' `
    -TenantId '00000000-0000-0000-0000-000000000000'

This example domain joins an Azure Storage Account to the AVD organizational unit in the Fabrikam.com domain.
#>

#Requires -Modules Az.Storage, Az.Accounts, ActiveDirectory
[Cmdletbinding()]
param 
(
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [String]$Environment = 'AzureCloud',

    [Parameter(Mandatory=$false)]
    [ValidateSet("AES256","RC4")]
    [String]$KerberosEncryptionType = 'RC4',

    [Parameter(Mandatory)]
    [String]$OuPath,

    [Parameter(Mandatory)]
    [String]$StorageAccountName,

    [Parameter(Mandatory)]
    [String]$StorageAccountResourceGroupName,

    [Parameter(Mandatory)]
    [String]$SubscriptionId,

    [Parameter(Mandatory)]
    [String]$TenantId
)


$ErrorActionPreference = 'Stop'


##############################################################
#  Variables
##############################################################
# Set Azure storage suffix
$StorageSuffix = switch($Environment)
{
    "AzureCloud"        {"core.windows.net"}
    "AzureUSGovernment" {"core.usgovcloudapi.net"}
}


# Get Domain information
$Domain = Get-ADDomain `
    -Current 'LocalComputer'

Write-Host "Collected domain information `n"


# Create suffix for storage account FQDN
$FilesSuffix = '.file.' + $StorageSuffix    


##############################################################
#  Process Storage Resources
##############################################################
# Connect to Azure
Connect-AzAccount `
    -Environment $Environment `
    -Tenant $TenantId `
    -Subscription $SubscriptionId | Out-Null

Write-Host "Connected to the target Azure Subscription `n"


# Create the Kerberos key for the Azure Storage Account
$Key = (New-AzStorageAccountKey `
    -ResourceGroupName $StorageAccountResourceGroupName `
    -Name $StorageAccountName `
    -KeyName 'kerb1' `
    | Select-Object -ExpandProperty 'Keys' `
    | Where-Object {$_.Keyname -eq 'kerb1'}).Value

Write-Host "Captured the Kerberos key for the Storage Account `n"


# Creates a password for the Azure Storage Account in AD using the Kerberos key
$ComputerPassword = ConvertTo-SecureString `
    -String $Key `
    -AsPlainText `
    -Force

Write-Host "Created the computer object password for the Azure Storage Account in AD DS `n"


# Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
$SPN = 'cifs/' + $StorageAccountName + $FilesSuffix


# Create the Description value for the Azure Storage Account; attribute for computer object in AD 
$Description = "Computer account object for Azure storage account $($StorageAccountName)."


# Check for existing AD computer object for the Azure Storage Account
$Computer = Get-ADComputer `
    -Filter {Name -eq $StorageAccountName}

Write-Host "Checked for an existing computer object for the Azure Storage Account in AD DS `n"


# Remove existing AD computer object for the Azure Storage Account
if($Computer)
{
    Remove-ADComputer `
        -Identity $StorageAccountName `
        -Confirm:$false | Out-Null

    Write-Host "Removed an existing computer object for the Azure Storage Account in AD DS `n"
}


# Create AD computer object for the Azure Storage Account
$ComputerObject = New-ADComputer `
    -Name $StorageAccountName `
    -Path $OuPath `
    -ServicePrincipalNames $SPN `
    -AccountPassword $ComputerPassword `
    -KerberosEncryptionType $KerberosEncryptionType `
    -Description $Description `
    -AllowReversiblePasswordEncryption $false `
    -Enabled $true `
    -PassThru

Write-Host "Created a new computer object for the Azure Storage Account in AD DS `n"


# Update the Azure Storage Account with the domain join 'INFO'
Set-AzStorageAccount `
    -ResourceGroupName $StorageAccountResourceGroupName `
    -Name $StorageAccountName `
    -EnableActiveDirectoryDomainServicesForFile $true `
    -ActiveDirectoryDomainName $Domain.DNSRoot `
    -ActiveDirectoryNetBiosDomainName $Domain.NetBIOSName `
    -ActiveDirectoryForestName $Domain.Forest `
    -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
    -ActiveDirectoryDomainSid $Domain.DomainSID `
    -ActiveDirectoryAzureStorageSid $ComputerObject.SID.Value `
    -ActiveDirectorySamAccountName $ComputerObject.SamAccountName `
    -ActiveDirectoryAccountType 'Computer' | Out-Null

Write-Host "Updated the Azure Storage Account with the domain and computer object properties `n"

# Enable AES256 encryption if selected
if($KerberosEncryptionType -eq 'AES256')
{
    # Set the Kerberos encryption on the computer object
    Set-ADComputer `
        -Identity $ComputerObject.DistinguishedName `
        -KerberosEncryptionType 'AES256' | Out-Null

    Write-Host "Set AES256 Kerberos encryption on the computer object for the Azure Storage Account in AD DS `n"

    
    # Reset the Kerberos key on the Storage Account
    $Key = (New-AzStorageAccountKey `
        -ResourceGroupName $StorageAccountResourceGroupName `
        -Name $StorageAccountName `
        -KeyName 'kerb2' `
        | Select-Object -ExpandProperty 'Keys' `
        | Where-Object {$_.Keyname -eq 'kerb2'}).Value

    Write-Host "Created a new Kerberos key on the Azure Storage Account to support AES256 Kerberos encryption `n"


    # Capture the Kerberos key as a secure string
    $NewPassword = ConvertTo-SecureString `
        -String $Key `
        -AsPlainText `
        -Force

    Write-Host "Created the computer object password for the Azure Storage Account in AD DS to support AES256 Kerberos encryption `n"


    # Update the password on the computer object with the new Kerberos key from the Storage Account
    Set-ADAccountPassword `
        -Identity $ComputerObject.DistinguishedName `
        -Reset `
        -NewPassword $NewPassword | Out-Null
    
    Write-Host "Updated the password on the computer object for the Azure Storage Account in AD DS `n"
}
