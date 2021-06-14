# Prerequisites
# Ensure your code signing certificate is available in an Azure Key Vault
# Stage your conversion XML files in an Azure Storage Account or repo

Param(

    [parameter(Mandatory)]
    [string]$ContainerName,

    [parameter(Mandatory)]
    [string]$PackagePath,

    [parameter(Mandatory)]
    [ValidateSet(500MB,1GB,5GB,10GB,20GB)]
    [int64]$Size 

)





Invoke-WebRequest -Uri "https://download.microsoft.com/download/d/9/7/d9707be8-06db-4b13-a992-48666aad8b78/91b9474c34904fe39de2b66827a93267.msixbundle" -OutFile "MsixPackagingTool.msixbundle"
Add-AppPackage -Path ".\MsixPackagingTool.msixbundle"
MsixPackagingTool.exe create-package --template c:\users\documents\ConversionTemplate.xml -v


$Vhd = New-VHD -SizeBytes $Size -Path "$HOME\Downloads\$ContainerName.vhd" -Dynamic -Confirm:$false | Mount-VHD -Passthru
$Disk = Initialize-Disk -Passthru -Number $Vhd.Number
$Partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $Disk.Number
Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $Partition.DriveLetter -Force
$ParentDirectory = $Partition.DriveLetter + ':\' + $ContainerName
New-Item -Path $ParentDirectory -ItemType Directory -Force
Invoke-WebRequest -Uri 'https://aka.ms/msixmgr' -OutFile "$HOME\Downloads\msixmgr.zip"
Expand-Archive -Path "$HOME\Downloads\msixmgr.zip" -DestinationPath "$HOME\Downloads\msixmgr" 
Start-Process -FilePath "$HOME\Downloads\msixmgr\x64\msixmgr.exe" -ArgumentList "-Unpack -packagePath $PackagePath -destination $ParentDirectory -applyacls"
Dismount-VHD -DiskNumber $Disk.Number