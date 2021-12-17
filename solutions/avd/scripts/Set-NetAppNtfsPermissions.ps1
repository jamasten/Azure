param 
(
    [Parameter(Mandatory)]
    [String]$DomainJoinPassword,

    [Parameter(Mandatory)]
    [String]$DomainJoinUserPrincipalName,

    [Parameter(Mandatory)]
    [String]$DomainServices,

    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalName,

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


    # Set the variables required to mount the Azure file share
    $FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName
    $Group = $Netbios + '\' + $SecurityPrincipalName
    $Username = 'Azure\' + $StorageAccountName
    $Password = ConvertTo-SecureString -String $StorageKey -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    # Mount file share
    New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential -Persist
    Write-Log -Message "Mounting the Azure file share succeeded" -Type 'INFO'

    # Set recommended NTFS permissions on the file share
    $ACL = Get-Acl -Path 'Z:'
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