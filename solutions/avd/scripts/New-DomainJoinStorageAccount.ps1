param 
(
    [Parameter(Mandatory=$false)]
    [String]$DomainAccountType = "ComputerAccount",

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
    [ValidateSet("AES256","RC4")]
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
    Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Scope 'CurrentUser'
    
    # Selects the appropriate suffix for the Azure Storage Account's UNC path
    $Suffix = switch($Environment)
    {
        AzureCloud {'.file.core.windows.net'}
        AzureUSGovernment {'.file.core.usgovcloudapi.net'}
    }
    Write-Log -Message "Storage Account Suffix = $Suffix" -Type 'INFO'

    if($DomainServices -eq 'Active Directory')
    {
        # Install latest NuGet Provider; recommended for PowerShellGet
        Install-PackageProvider -Name 'NuGet' -Force -ErrorAction 'Stop'
        Write-Log -Message "Installed the NuGet Package Provider" -Type 'INFO'

        # Install PowerShellGet; prereq for the Az.Storage module
        Install-Module -Name 'PowerShellGet' -Force -ErrorAction 'Stop'
        Write-Log -Message "Installed the PowerShellGet module" -Type 'INFO'

        # Install required Az.Storage module
        Install-Module -Name 'Az.Storage' -Repository 'PSGallery' -Force -ErrorAction 'Stop'
        Write-Log -Message "Installed the Az.Storage module" -Type 'INFO'

        # Connects to Azure using a User Assigned Managed Identity
        Connect-AzAccount -Identity -Tenant $TenantId -Subscription $SubscriptionId -ErrorAction 'Stop'
        Write-Log -Message "Authenticated to Azure" -Type 'INFO'

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
        Write-Log -Message "Acquired Kerberos Key from Storage Account" -Type 'INFO'

        # Install Active Directory PowerShell module
        Install-WindowsFeature -Name 'RSAT-AD-PowerShell' -ErrorAction 'Stop'
        Write-Log -Message "Installation of the AD module succeeded" -Type 'INFO'

        # Create credential for domain joining the Azure Storage Account
        $Username = $DomainJoinUserPrincipalName
        $Password = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
        [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

        # Creates a password for the Azure Storage Account in AD using the Kerberos key
        $ComputerPassword = ConvertTo-SecureString -String $Key.Replace("'","") -AsPlainText -Force -ErrorAction Stop
        Write-Log -Message "Secure string conversion succeeded" -Type 'INFO'

        # Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
        $SPN = 'cifs/' + $StorageAccountName + $Suffix

        # Create the Description value for the Azure Storage Account; attribute for computer object in AD 
        $Description = "Computer account object for Azure storage account $($StorageAccountName)."

        # Create the AD computer object for the Azure Storage Account
        New-ADComputer -Credential $Credential -Name $StorageAccountName -Path $OuPath -ServicePrincipalNames $SPN -AccountPassword $ComputerPassword -KerberosEncryptionType $KerberosEncryptionType -Description $Description -ErrorAction 'Stop'
        Write-Log -Message "Computer object creation succeeded" -Type 'INFO'

        # Get domain 'INFO' required for the Azure Storage Account
        $Domain = Get-ADDomain -Credential $Credential -Current 'LocalComputer' -ErrorAction 'Stop'
        Write-Log -Message "Domain 'INFO' collection succeeded" -Type 'INFO'

        # Get the SID for the Azure Storage Account Computer Object in AD
        $ComputerSid = (Get-ADComputer -Identity $StorageAccountName -ErrorAction 'Stop').SID.Value
        Write-Log -Message "Computer object 'INFO' collection succeeded" -Type 'INFO'

        # Update the Azure Storage Account with the domain join 'INFO'
        Set-AzStorageAccount `
            -ResourceGroupName $ResourceGroupName `
            -Name $StorageAccountName `
            -EnableActiveDirectoryDomainServicesForFile $true `
            -ActiveDirectoryDomainName $Domain.DNSRoot `
            -ActiveDirectoryNetBiosDomainName $Domain.NetBIOSName `
            -ActiveDirectoryForestName $Domain.Forest `
            -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
            -ActiveDirectoryDomainsid $Domain.DomainSID `
            -ActiveDirectoryAzureStorageSid $ComputerSid `
            -ErrorAction 'Stop'
        Write-Log -Message "Storage Account update with domain join info succeeded" -Type 'INFO'
    }

    # Set the variables required to mount the Azure file share
    $FileShare = '\\' + $StorageAccountName + $Suffix + '\' + $HostPoolName
    $Group = $Netbios + '\' + $SecurityPrincipalName
    $Username = 'Azure\' + $StorageAccountName
    $Password = ConvertTo-SecureString -String $StorageKey -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

    # Mount file share
    New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential -Persist -ErrorAction 'Stop'
    Write-Log -Message "Mounting the Azure file share succeeded" -Type 'INFO'

    # Set recommended NTFS permissions on the file share
    Start-Process icacls -ArgumentList "Z: /grant $($Group):(M)" -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /grant "Creator Owner":(OI)(CI)(IO)(M)' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Authenticated Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Start-Process icacls -ArgumentList 'Z: /remove "Builtin\Users"' -Wait -NoNewWindow -PassThru -ErrorAction 'Stop'
    Write-Log -Message "Setting the NTFS permissions on the Azure file share succeeded" -Type 'INFO'

    # Unmount file share
    Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force -ErrorAction 'Stop'
    Write-Log -Message "Unmounting the Azure file share succeeded" -Type 'INFO'
}
catch {
    Write-Log -Message $_ -Type 'ERROR'
}