param 
( 
    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$HostPoolName,

    [Parameter(Mandatory)]
    [String]$Netbios,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalName,

    [Parameter(Mandatory)]
    [String]$StorageAccountName
)

$Suffix = switch($Environment)
{
    AzureCloud {'.file.core.windows.net'}
    AzureUSGovernment {'.file.core.usgovcloudapi.net'}
}
$FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName
$Group = $Netbios + '\' + $SecurityPrincipalName

New-PSDrive -Name Z -PSProvider FileSystem -Root $FileShare -Persist -ErrorAction Stop

Start-Process icacls -ArgumentList "Z: /grant $($Group):(M)" -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /grant "Creator Owner":(OI)(CI)(IO)(M)' -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /remove "Authenticated Users"' -Wait -NoNewWindow -PassThru -ErrorAction Stop
Start-Process icacls -ArgumentList 'Z: /remove "Builtin\Users"' -Wait -NoNewWindow -PassThru -ErrorAction Stop

Remove-PSDrive -Name Z -PSProvider FileSystem -Force -ErrorAction Stop