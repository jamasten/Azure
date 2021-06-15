# Prerequisites
# Ensure your code signing certificate is available in an Azure Key Vault
# Stage the application and its associated conversion XML file in an Azure Storage Account Container
# Established an SMB share for the MSIX App Attach images

Param(

    [parameter(Mandatory)]
    [string]$ApplicationUri,

    [parameter(Mandatory)]
    [string]$ApplicationShortName,

    [parameter(Mandatory)]
    [string]$ConversionTemplateUri,

    [parameter(Mandatory)]
    [ValidateSet(500MB,1GB,5GB,10GB,20GB)]
    [int64]$ImageSize,

    [parameter(Mandatory)]
    [string]$PackagePath,

    [parameter(Mandatory)]
    [string]$SasToken

)

# Downloads the MSIX Packaging Tool
Invoke-WebRequest -Uri "https://download.microsoft.com/download/d/9/7/d9707be8-06db-4b13-a992-48666aad8b78/91b9474c34904fe39de2b66827a93267.msixbundle" -OutFile "MsixPackagingTool.msixbundle"

# Installs the MSIX Packaging Tool
Add-AppPackage -Path ".\MsixPackagingTool.msixbundle"

# Downloads the application installer
Invoke-WebRequest -Uri $($ApplicationUri + $SasToken) -OutFile $($HOME + '\Downloads\' + $ApplicationShortName + '.' + $ApplicationUri.Split('.')[-1])

# Downloads the application conversion template
Invoke-WebRequest -Uri $($ConversionTemplateUri + $SasToken) -OutFile $($HOME + '\Downloads\' + $ApplicationShortName + '.xml')

# Creates MSIX pacakage of the application
Start-Process -FilePath ".\MsixPackagingTool.exe" -ArgumentList "create-package $($HOME + '\Downloads\' + $ApplicationShortName + '.xml') -v"

# Stops the Shell HW Detection service to prevent the format disk popup
Stop-Service -Name ShellHWDetection -Force

# Creates a dynamic VHDX 
$Vhdx = New-VHD -SizeBytes $Size -Path "$HOME\Downloads\$ApplicationShortName.vhdx" -Dynamic -Confirm:$false | Mount-VHD -Passthru

# Initializes the mounted VHDX
$Disk = Initialize-Disk -Passthru -Number $Vhdx.Number

# Creates a partition on the mounted VHDX using all the drive space
$Partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskNumber $Disk.Number

# Formats the partition using NTFS
Format-Volume -FileSystem NTFS -Confirm:$false -DriveLetter $Partition.DriveLetter -Force

# Sets the root folder name in the VHDX to store the unpacked MSIX package
$ParentDirectory = $Partition.DriveLetter + ':\' + $ApplicationShortName

# Creates the root folder in the VHDX to store the unpacked MSIX package
New-Item -Path $ParentDirectory -ItemType Directory -Force

# Downloads the MSIXMGR tool to unpack the MSIX package
Invoke-WebRequest -Uri 'https://aka.ms/msixmgr' -OutFile "$HOME\Downloads\msixmgr.zip"

# Extracts the ZIP file containing the MSIXMGR tool
Expand-Archive -Path "$HOME\Downloads\msixmgr.zip" -DestinationPath "$HOME\Downloads\msixmgr"

# Unpacks the MSIX Package and adds it to the mounted VHDX, inside the parent directory
Start-Process -FilePath "$HOME\Downloads\msixmgr\x64\msixmgr.exe" -ArgumentList "-Unpack -packagePath $PackagePath -destination $ParentDirectory -applyacls"

# Dismounts the VHDX
Dismount-VHD -DiskNumber $Disk.Number

# Uploads the VHDX to the file share
