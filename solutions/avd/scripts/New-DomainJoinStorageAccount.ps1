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

# Install Active Directory PowerShell Module
Install-WindowsFeature -Name 'RSAT-AD-PowerShell' -ErrorAction 'Stop'

# This is the required exectuion policy for the domain join script for the storage account
Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Force -ErrorAction 'Stop'

# Create a temp directory to store the AzFilesHybrid module
New-Item -Path 'C:\' -Name 'Temp' -ItemType 'Directory' -ErrorAction 'SilentlyContinue'

# Download the AzFilesHybrid module
Invoke-WebRequest `
    -Uri 'https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip' `
    -OutFile 'C:\Temp\AzFilesHybrid.zip' `
    -ErrorAction 'Stop'

# Extract the AzFilesHybrid module
Expand-Archive `
    -LiteralPath 'C:\Temp\AzFilesHybrid.zip' `
    -DestinationPath 'C:\Temp' `
    -Force `
    -ErrorAction 'Stop'

$Username = $Netbios + '\' + $DomainJoinUsername
$Password = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

Invoke-Command -Credential $Credential -ComputerName $env:COMPUTERNAME -ScriptBlock {

    # Setting the working directory to the temp directory
    Set-Location -Path 'C:\Temp' -ErrorAction 'Stop'

    # Copy AzFilesHybrid module files to file system
    & C:\Temp\CopyToPSPath.ps1 

    # Install latest NuGet Provider; recommended for PowerShellGet
    Install-PackageProvider -Name 'NuGet' -Force -ErrorAction 'Stop'

    # Install PowerShellGet; prereq for the AZ module
    Install-Module -Name 'PowerShellGet' -Force -ErrorAction 'Stop'

    # Install the required Az modules; prereq for the AzFilesHybrid module
    # The full Az module package takes 30 mins to install and should be avoided
    Install-Module -Name 'Az.Accounts' -Scope 'CurrentUser' -Repository 'PSGallery' -Force -ErrorAction 'Stop'
    Install-Module -Name 'Az.Network' -Scope 'CurrentUser' -Repository 'PSGallery' -Force -ErrorAction 'Stop'
    Install-Module -Name 'Az.Resources' -Scope 'CurrentUser' -Repository 'PSGallery' -Force -ErrorAction 'Stop'
    Install-Module -Name 'Az.Storage' -Scope 'CurrentUser' -Repository 'PSGallery' -Force -ErrorAction 'Stop'

    # Imports the AzFilesHybrid module
    Import-Module -Name 'AzFilesHybrid' -Force -ErrorAction 'Stop'

    # Connects to Azure using a User Assigned Managed Identity
    Connect-AzAccount -Identity -ErrorAction 'Stop'

    # Domain join the Azure Storage Account
    Join-AzStorageAccountForAuth `
            -ResourceGroupName $using:ResourceGroupName `
            -StorageAccountName $using:StorageAccountName `
            -DomainAccountType $using:DomainAccountType `
            -OrganizationalUnitDistinguishedName $using:OuPath `
            -EncryptionType $using:KerberosEncryptionType `
            -ErrorAction 'Stop'

    # Set variables to mount file share
    $Suffix = switch($using:Environment)
    {
        AzureCloud {'.file.core.windows.net'}
        AzureUSGovernment {'.file.core.usgovcloudapi.net'}
    }
    $FileShare = '\\' + $using:StorageAccountName + $Suffix + '\' + $using:HostPoolName
    $Group = $using:Netbios + '\' + $using:SecurityPrincipalName
    $Username = 'Azure\' + $using:StorageAccountName
    $Password = ConvertTo-SecureString -String $using:StorageKey -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    # Mount file share
    New-PSDrive -Name Z -PSProvider FileSystem -Root $FileShare -Credential $Credential -Persist -ErrorAction 'Stop'

    # Set recommended NTFS permissions on the file share
    Start-Process icacls -ArgumentList "Z: /grant $($Group):(M)" -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /grant "Creator Owner":(OI)(CI)(IO)(M)' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Authenticated Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Builtin\Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'

    # Unmount file share
    Remove-PSDrive -Name Z -PSProvider FileSystem -Force -ErrorAction 'Stop'

} -ErrorAction Stop