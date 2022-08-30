[CmdletBinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $FileShareNames,

    [parameter(Mandatory)]
    [string]
    $KeyVaultName,

    [parameter(Mandatory)]
    [string]
    $StorageAccountNames,

    [parameter(Mandatory)]
    [string]
    $StorageAccountSuffix,

    [parameter(Mandatory)]
    [string]
    $SubscriptionId,

    [parameter(Mandatory)]
    [string]
    $TenantId,

    [parameter(Mandatory)]
    [string]
    $UserAssignedIdentityClientId
)


##############################################################
#  Functions
##############################################################
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
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

function Get-WebFile
{
    param(
        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [string]$URL
    )
    $Counter = 0
    do
    {
        Invoke-WebRequest -Uri $URL -OutFile $FileName -ErrorAction 'SilentlyContinue'
        if($Counter -gt 0)
        {
            Start-Sleep -Seconds 30
        }
        $Counter++
    }
    until((Test-Path $FileName) -or $Counter -eq 9)
}

try 
{
    ##############################################################
    #  Variables
    ##############################################################
	$ErrorActionPreference = 'Stop'

	$FilesSuffix = '.file.' + $StorageAccountSuffix
	Write-Log -Message "Azure Files Suffix = $FilesSuffix" -Type 'INFO'

    # Convert FileShareNames from a JSON array to a PowerShell array
    [array]$Shares = $FileShareNames.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "File Shares:" -Type 'INFO'
    $Shares | Add-Content -Path 'C:\cse.txt' -Force

    # Convert StorageAccountNames from a JSON array to a PowerShell array
    [array]$StorageAccounts = $StorageAccountNames.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "File Shares:" -Type 'INFO'
    $StorageAccounts | Add-Content -Path 'C:\cse.txt' -Force


	##############################################################
    #  Install Prerequisites
    ##############################################################
    # Install latest NuGet Provider; recommended for PowerShellGet
    $NuGet = Get-PackageProvider | Where-Object {$_.Name -eq 'NuGet'}
    if(!$NuGet)
    {
        Install-PackageProvider -Name 'NuGet' -Force
        Write-Log -Message "Installed the NuGet Package Provider successfully" -Type 'INFO'
    }
    else
    {
        Write-Log -Message "NuGet Package Provider already exists" -Type 'INFO'    
    }
    
    # Install required Az.KeyVault module
    $AzKeyVaultModule = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'Az.KeyVault'}
    if(!$AzKeyVaultModule)
    {
        Install-Module -Name 'Az.KeyVault' -Repository 'PSGallery' -Force
        Write-Log -Message "Installed the Az.KeyVault module successfully" -Type 'INFO'
    }
    else 
    {
        Write-Log -Message "Az.KeyVault module already exists" -Type 'INFO'
    }

	# Download the tool
	$URL = 'https://github.com/FSLogix/Invoke-FslShrinkDisk/archive/refs/heads/master.zip'
	$ZIP = 'fds.zip'
	Invoke-WebRequest -Uri $URL -OutFile $ZIP
	Write-Log -Message 'Downloaded the tool successfully' -Type 'INFO'


	# Extract the tool from the ZIP archive
	Expand-Archive -LiteralPath $ZIP -Force
	Write-Log -Message 'Extracted the tool from the ZIP archive successfully' -Type 'INFO'


    ##############################################################
    #  Process File Shares
	##############################################################
    foreach($StorageAccount in $StorageAccounts)
    {
        $FileServer = '\\' + $StorageAccount + $FilesSuffix

        # Get the storage account key
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId
        $StorageAccountKey = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $StorageAccount).SecretValue
        Write-Log -Message "Acquired the Storage Account key for $StorageAccountName from the Key Vault successfully" -Type 'INFO'

        # Create credential for accessing the storage account
        $Username = 'Azure\' + $StorageAccount
        [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $StorageAccountKey)

        
        foreach($Share in $Shares)
        {
            # Mount file share
            $FileShare = $FileServer + '\' + $Share
            New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential
            Write-Log -Message "Mounting the Azure file share, $FileShare, succeeded" -Type 'INFO'

            # Run the tool
            & .\fds\Invoke-FslShrinkDisk-master\Invoke-FslShrinkDisk.ps1 -Path $FileShare -Recurse # Add parameters
            Write-Log -Message 'Ran the tool successfully' -Type 'INFO'

            # Unmount file share
            Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force
            Start-Sleep -Seconds 5
            Write-Log -Message "Unmounting the Azure file share, $FileShare, succeeded" -Type 'INFO'
        }
    }
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    $ErrorData = $_ | Select-Object *
    $ErrorData | Out-File -FilePath 'C:\cse.txt' -Append
    throw
}