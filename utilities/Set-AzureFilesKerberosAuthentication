#Requires -Modules Az.Storage, Az.Accounts, ActiveDirectory
[Cmdletbinding()]
param 
(
    [Parameter(Mandatory)]
    [SecureString]$DomainJoinPassword,

    [Parameter(Mandatory=$false)]
    [String]$DomainJoinUserPrincipalName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [String]$Environment = 'AzureCloud',

    [Parameter(Mandatory=$false)]
    [ValidateSet("AES256","RC4")]
    [String]$KerberosEncryptionType = 'RC4',

    [Parameter(Mandatory=$false)]
    [String]$Netbios,

    [Parameter(Mandatory=$false)]
    [String]$OuPath,

    [Parameter(Mandatory=$false)]
    [String]$StorageAccountName,

    [Parameter(Mandatory=$false)]
    [String]$StorageAccountResourceGroupName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("core.windows.net","core.usgovcloudapi.net")]
    [String]$StorageSuffix = 'core.windows.net',

    [Parameter(Mandatory=$false)]
    [String]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [String]$TenantId
)


$ErrorActionPreference = 'Stop'


##############################################################
#  Variables
##############################################################
# Create Domain credential
[pscredential]$DomainCredential = New-Object System.Management.Automation.PSCredential ($DomainJoinUserPrincipalName, $DomainJoinPassword)

# Get Domain information
$Domain = Get-ADDomain -Credential $DomainCredential -Current 'LocalComputer'
$FilesSuffix = '.file.' + $StorageSuffix    


##############################################################
#  Process Storage Resources
##############################################################
# Connects to Azure using a User Assigned Managed Identity
Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId

# Get the storage account key
$StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName)[0].Value

# Create credential for accessing the storage account
$StorageUsername = 'Azure\' + $StorageAccountName
$StoragePassword = ConvertTo-SecureString -String "$($StorageKey)" -AsPlainText -Force
[pscredential]$StorageKeyCredential = New-Object System.Management.Automation.PSCredential ($StorageUsername, $StoragePassword)
$Credential = $StorageKeyCredential

# Get / create kerberos key for Azure Storage Account
$KerberosKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
if(!$KerberosKey)
{
    New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1
    $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
} 
else 
{
    $Key = $KerberosKey
}

# Creates a password for the Azure Storage Account in AD using the Kerberos key
$ComputerPassword = ConvertTo-SecureString -String $Key.Replace("'","") -AsPlainText -Force

# Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
$SPN = 'cifs/' + $StorageAccountName + $FilesSuffix

# Create the Description value for the Azure Storage Account; attribute for computer object in AD 
$Description = "Computer account object for Azure storage account $($StorageAccountName)."

# Create the AD computer object for the Azure Storage Account
$Computer = Get-ADComputer -Credential $DomainCredential -Filter {Name -eq $StorageAccountName}
if($Computer)
{
    Remove-ADComputer -Credential $DomainCredential -Identity $StorageAccountName -Confirm:$false
}
$ComputerObject = New-ADComputer -Credential $DomainCredential -Name $StorageAccountName -Path $OuPath -ServicePrincipalNames $SPN -AccountPassword $ComputerPassword -KerberosEncryptionType $KerberosEncryptionType -Description $Description -PassThru

# Update the Azure Storage Account with the domain join 'INFO'
Set-AzStorageAccount `
    -ResourceGroupName $StorageAccountResourceGroupName `
    -Name $StorageAccountName `
    -EnableActiveDirectoryDomainServicesForFile $true `
    -ActiveDirectoryDomainName $Domain.DNSRoot `
    -ActiveDirectoryNetBiosDomainName $Domain.NetBIOSName `
    -ActiveDirectoryForestName $Domain.Forest `
    -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
    -ActiveDirectoryDomainsid $Domain.DomainSID `
    -ActiveDirectoryAzureStorageSid $ComputerObject.SID.Value `
    -ActiveDirectorySamAccountName $ComputerObject.SamAccountName `
    -ActiveDirectoryAccountType 'Computer'
            
# Enable AES256 encryption if selected
if($KerberosEncryptionType -eq 'AES256')
{
    # Set the Kerberos encryption on the computer object
    $DistinguishedName = 'CN=' + $StorageAccountName + ',' + $OuPath
    Set-ADComputer -Credential $Credential -Identity $DistinguishedName -KerberosEncryptionType 'AES256'
    
    # Reset the Kerberos key on the Storage Account
    New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1
    $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value

    # Update the password on the computer object with the new Kerberos key on the Storage Account
    $NewPassword = ConvertTo-SecureString -String $Key -AsPlainText -Force
    Set-ADAccountPassword -Credential $Credential -Identity $DistinguishedName -Reset -NewPassword $NewPassword
}

