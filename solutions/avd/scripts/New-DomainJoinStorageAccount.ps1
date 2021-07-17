param 
(
    [Parameter(Mandatory=$false)]
    [String]$DomainAccountType = "ComputerAccount",

    [Parameter(Mandatory)]
    [String]$DomainJoinPassword,

    [Parameter(Mandatory)]
    [String]$DomainJoinUsername,

    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [ValidateSet("AES256","RC4","AES256,RC4")]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [String]$Netbios,

    [Parameter(Mandatory)]
    [String]$OuPath,

    [Parameter(Mandatory)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalName,

    [Parameter(Mandatory)]
    [String]$StorageAccountName,

    [Parameter(Mandatory)]
    [String]$StorageKey,

    [Parameter(Mandatory)]
    [String]$SubscriptionId,

    [Parameter(Mandatory)]
    [String]$TenantId
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.log'
    if(!(Test-Path -Path C:\cse.log))
    {
        New-Item -Path C:\ -Name cse.log | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

try 
{    
    # Install latest NuGet Provider; recommended for PowerShellGet
    Install-PackageProvider -Name 'NuGet' -Force -ErrorAction 'Stop'

    # Install PowerShellGet; prereq for the Az.Storage module
    Install-Module -Name 'PowerShellGet' -Force -ErrorAction 'Stop'

    # Install required Az.Storage module
    Install-Module -Name 'Az.Storage' -Scope 'CurrentUser' -Repository 'PSGallery' -Force -ErrorAction 'Stop'

    # Connects to Azure using a User Assigned Managed Identity
    Connect-AzAccount -Identity -Tenant $TenantId -Subscription $SubscriptionId -ErrorAction 'Stop'

    # Get / create kerberos key for Azure Storage Account
    $Test = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
    if(!$Test)
    {
        New-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -KeyName kerb1
        $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
    } 
    else 
    {
        $Key = $Test
    }
    Write-Log -Message "" -Type INFO

    # Install Active Directory PowerShell module
    Install-WindowsFeature -Name 'RSAT-AD-PowerShell' -ErrorAction 'Stop'
    Write-Log -Message "Installation of the AD module succeeded" -Type INFO

    # Create credential for domain joining the Azure Storage Account
    $Username = $Netbios + '\' + $DomainJoinUsername
    $Password = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    # Selects the appropriate suffix for the Azure Storage Account's UNC path
    $Suffix = switch($Environment)
    {
        AzureCloud {'.file.core.windows.net'}
        AzureUSGovernment {'.file.core.usgovcloudapi.net'}
    }
    Write-Log -Message "Storage Account Suffix = $Suffix" -Type INFO

    # Creates a password for the Azure Storage Account in AD using the Kerberos key
    $ComputerPassword = ConvertTo-SecureString -String $Key.Replace("'","") -AsPlainText -Force -ErrorAction Stop
    Write-Log -Message "Secure string conversion succeeded" -Type INFO

    # Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
    $SPN = 'cifs/' + $StorageAccountName + $Suffix

    # Create the Description value for the Azure Storage Account; attribute for computer object in AD 
    $Description = "Computer account object for Azure storage account $($StorageAccountName)."

    # Create the AD computer object for the Azure Storage Account
    New-ADComputer -Credential $Credential -Name $StorageAccountName -ServicePrincipalNames $SPN -AccountPassword $ComputerPassword -KerberosEncryptionType $KerberosEncryptionType -Description $Description -ErrorAction 'Stop'
    Write-Log -Message "Computer object creation succeeded" -Type INFO

    # Get domain info required for the Azure Storage Account
    $Domain = Get-ADDomain -Credential $Credential -Current 'LocalComputer' -ErrorAction 'Stop'
    Write-Log -Message "Domain info collection succeeded" -Type INFO

    # Get the SID for the Azure Storage Account Computer Object in AD
    $ComputerSid = (Get-ADComputer -Identity $StorageAccountName -ErrorAction 'Stop').SID.Value
    Write-Log -Message "Computer object info collection succeeded" -Type INFO

    # Update the Azure Storage Account with the domain join info
    Set-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName `
        -EnableActiveDirectoryDomainServicesForFile $true `
        -ActiveDirectoryDomainName $Domain.DNSRoot `
        -ActiveDirectoryNetBiosDomainName $Netbios `
        -ActiveDirectoryForestName $Domain.Forest `
        -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
        -ActiveDirectoryDomainsid $Domain.DomainSID `
        -ActiveDirectoryAzureStorageSid $ComputerSid
    Write-Log -Message "Storage Account update with domain join info succeeded" -Type INFO

    # Set the variables required to mount the Azure file share
    $FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName
    $Group = $Netbios + '\' + $SecurityPrincipalName
    $Username = 'Azure\' + $StorageAccountName
    $Password = ConvertTo-SecureString -String $StorageKey -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    # Mount file share
    New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential -Persist -ErrorAction 'Stop'
    Write-Log -Message "Mounting the Azure file share succeeded" -Type INFO

    # Set recommended NTFS permissions on the file share
    Start-Process icacls -ArgumentList "Z: /grant $($Group):(M)" -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /grant "Creator Owner":(OI)(CI)(IO)(M)' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Authenticated Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Builtin\Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Write-Log -Message "Setting the NTFS permissions on the Azure file share succeeded" -Type INFO

    # Unmount file share
    Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force -ErrorAction 'Stop'
    Write-Log -Message "Unmounting the Azure file share succeeded" -Type INFO
}
catch {
    
}