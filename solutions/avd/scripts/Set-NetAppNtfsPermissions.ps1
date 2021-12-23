param 
(
    [Parameter(Mandatory)]
    [String]$DomainJoinPassword,

    [Parameter(Mandatory)]
    [String]$DomainJoinUserPrincipalName,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [String]$ResourceNameSuffix,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalName,

    [Parameter(Mandatory)]
    [String]$SmbServerLocation
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path C:\ -Name cse.txt | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

$ErrorActionPreference = 'Stop'

try 
{
    # Install Active Directory PowerShell module
    Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
    Write-Log -Message "Installation of the AD module succeeded" -Type 'INFO'

    # Create credential for getting Active Directory information
    $Username = $DomainJoinUserPrincipalName
    $Password = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    $SmbServerName = (Get-ADComputer -Filter "Name -like 'anf-$SmbServerLocation*'" -Credential $Credential).Name
    $Domain = ($DomainJoinUserPrincipalName -split '@')[1]

    # Set the variables required to mount the Azure file share
    $FileShare = '\\' + $SmbServerName + '.' + $Domain + '\' + $HostPoolName
    $Group = $Netbios + '\' + $SecurityPrincipalName

    # Mount file share
    New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential -Persist
    Write-Log -Message "Mounting the Azure file share succeeded" -Type 'INFO'

    # Set recommended NTFS permissions on the file share
    $ACL = Get-Acl -Path 'Z:'
    $Everyone = New-Object System.Security.Principal.Ntaccount ("Everyone")
    $ACL.PurgeAccessRules($Everyone)
    $CreatorOwner = New-Object System.Security.Principal.Ntaccount ("Creator Owner")
    $ACL.PurgeAccessRules($CreatorOwner)
    $AuthenticatedUsers = New-Object System.Security.Principal.Ntaccount ("Authenticated Users")
    $ACL.PurgeAccessRules($AuthenticatedUsers)
    $Users = New-Object System.Security.Principal.Ntaccount ("Users")
    $ACL.PurgeAccessRules($Users)
    $DomainUsers = New-Object System.Security.AccessControl.FileSystemAccessRule("$Group","Modify","None","None","Allow")
    $ACL.SetAccessRule($DomainUsers)
    $CreatorOwner = New-Object System.Security.AccessControl.FileSystemAccessRule("Creator Owner","Modify","ContainerInherit,ObjectInherit","InheritOnly","Allow")
    $ACL.AddAccessRule($CreatorOwner)
    $ACL | Set-Acl -Path 'Z:'
    Write-Log -Message "Setting the NTFS permissions on the Azure file share succeeded" -Type 'INFO'

    # Unmount file share
    Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force
    Write-Log -Message "Unmounting the Azure file share succeeded" -Type 'INFO'
}
catch {
    Write-Log -Message $_ -Type 'ERROR'
    $ErrorData = $_ | Select-Object *
    $ErrorData | Out-File -FilePath 'C:\cse.txt' -Append
    throw
}