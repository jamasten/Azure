param 
(
    [Parameter(Mandatory)]
    [String]$ClientId,

    [Parameter(Mandatory=$false)]
    [String]$DomainAccountType = "ComputerAccount",

    [Parameter(Mandatory)]
    [ValidateSet("AES256","RC4","AES256,RC4")]
    [String]$EncryptionType,

    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [String]$Netbios,

    [Parameter(Mandatory)]
    [String]$OuDistinguishedName,

    [Parameter(Mandatory)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalName,

    [Parameter(Mandatory)]
    [String]$StorageKey,

    [Parameter(Mandatory)]
    [String]$StorageAccountName,

    [Parameter(Mandatory)]
    [String]$SubscriptionId
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

Install-WindowsFeature -Name 'RSAT-AD-PowerShell'

Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Scope 'CurrentUser'

Invoke-WebRequest `
    -Uri 'https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip' `
    -OutFile 'C:\Temp\AzFilesHybrid.zip'

Expand-Archive `
    -LiteralPath 'C:\Temp\AzFilesHybrid.zip' `
    -DestinationPath 'C:\Temp' `
    -Force `
    -Verbose

& C:\Temp\CopyToPSPath.ps1 

Import-Module -Name 'AzFilesHybrid'

Connect-AzAccount -Identity -AccountId $ClientId

Select-AzSubscription -SubscriptionId $SubscriptionId 

Join-AzStorageAccountForAuth `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName `
        -EncryptionType $EncryptionType
        
$Suffix = switch($Environment)
{
    AzureCloud {'.file.core.windows.net'}
    AzureUSGovernment {'.file.core.usgovcloudapi.net'}
}
$FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName
$Group = $Netbios + '\' + $SecurityPrincipalName
$Username = 'Azure\' + $StorageAccountName
$Password = ConvertTo-SecureString -String $StorageKey -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

New-PSDrive -Name Z -PSProvider FileSystem -Root $FileShare -Credential $Credential -Persist -ErrorAction Stop

Start-Process icacls -ArgumentList "Z: /grant $($Group):(M)" -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /grant "Creator Owner":(OI)(CI)(IO)(M)' -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /remove "Authenticated Users"' -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /remove "Builtin\Users"' -Wait -NoNewWindow -PassThru -ErrorAction Stop

Remove-PSDrive -Name Z -PSProvider FileSystem -Force -ErrorAction Stop