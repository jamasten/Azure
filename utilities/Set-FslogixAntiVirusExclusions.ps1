##############################################################
# Add AntiVirus Exclusions for FSLogix in Windows Defender
##############################################################
# https://learn.microsoft.com/en-us/fslogix/overview-prerequisites#configure-antivirus-file-and-folder-exclusions

[Cmdletbinding()]
Param(
    [parameter(Mandatory=$false)]
    [switch]$CloudCache,

    [parameter(Mandatory=$false)]
    [string[]]$FileShareUncPaths,

    [parameter(Mandatory)]
    [ValidateSet('AzureBlobs','AzureFiles','AzureNetAppFiles')]
    [string]$StorageService
)

# These are the initial files that should be excluded using any storage service and FSLogix configuration
$Files = @(
    "%TEMP%\*\*.VHD",
    "%TEMP%\*\*.VHDX",
    "%Windir%\TEMP\*\*.VHD",
    "%Windir%\TEMP\*\*.VHDX"
)

# These are the files to exclude when using an SMB share
if($StorageService -eq 'AzureFiles' -or $StorageService -eq 'AzureNetAppFiles')
{
    foreach($FileShareUncPath in $FileShareUncPaths)
    {
        $Files += "$FileShareUncPath\*\*.VHD"
        $Files += "$FileShareUncPath\*\*.VHD.lock"
        $Files += "$FileShareUncPath\*\*.VHD.meta"
        $Files += "$FileShareUncPath\*\*.VHD.metadata"
        $Files += "$FileShareUncPath\*\*.VHDX"
        $Files += "$FileShareUncPath\*\*.VHDX.lock"
        $Files += "$FileShareUncPath\*\*.VHDX.meta"
        $Files += "$FileShareUncPath\*\*.VHDX.metadata"
    }
}

# These are the files and folders to exclude when using Cloud Cache
if($CloudCache)
{ 
    $Files += @(
        "%ProgramData%\FSLogix\Cache\*"
        "%ProgramData%\FSLogix\Proxy\*"
    )
}

foreach($File in $Files)
{
    Add-MpPreference -ExclusionPath $File -ErrorAction 'Stop'
}