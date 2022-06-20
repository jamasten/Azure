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
    [ValidateSet("AES256","RC4")]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [String]$Netbios,

    [Parameter(Mandatory)]
    [String]$OuPath,

    [Parameter(Mandatory)]
    [Array]$SecurityPrincipalNames,

    [Parameter(Mandatory)]
    [Int]$StorageCount,

    [Parameter(Mandatory)]
    [Int]$StorageIndex,

    [Parameter(Mandatory)]
    [String]$StorageAccountPrefix,

    [Parameter(Mandatory)]
    [String]$StorageAccountResourceGroupName,

    [Parameter(Mandatory)]
    [String]$StorageSuffix,

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
    # Install latest NuGet Provider; recommended for PowerShellGet
    Install-PackageProvider -Name 'NuGet' -Force
    Write-Log -Message "Installed the NuGet Package Provider" -Type 'INFO'

    # Install PowerShellGet; prereq for the Az.Storage module
    Install-Module -Name 'PowerShellGet' -Force
    Write-Log -Message "Installed the PowerShellGet module" -Type 'INFO'

    # Install required Az.Storage module
    Install-Module -Name 'Az.Storage' -Repository 'PSGallery' -Force
    Write-Log -Message "Installed the Az.Storage module" -Type 'INFO'

    # Connects to Azure using a User Assigned Managed Identity
    Connect-AzAccount -Identity -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId
    Write-Log -Message "Authenticated to Azure" -Type 'INFO'

    $FilesSuffix = '.file.' + $StorageSuffix
    Write-Log -Message "Azure Files Suffix = $FilesSuffix" -Type 'INFO'

    for($i = $StorageIndex; $i -lt ($StorageIndex + $StorageCount); $i++)
    {
        $SecurityGroupName = $SecurityPrincipalNames[$i]
        $StorageAccountName = $StorageAccountPrefix + $i.ToString().PadLeft(2,'0')
        
        # Domain join the storage account if using AD DS
        if($DomainServices -eq 'ActiveDirectory')
        {
            # Get / create kerberos key for Azure Storage Account
            $Test = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
            if(!$Test)
            {
                New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1
                $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
            } 
            else 
            {
                $Key = $Test
            }
            Write-Log -Message "Acquired Kerberos Key from Storage Account" -Type 'INFO'

            # Install Active Directory PowerShell module
            Install-WindowsFeature -Name 'RSAT-AD-PowerShell'
            Write-Log -Message "Installation of the AD module succeeded" -Type 'INFO'

            # Create credential for domain joining the Azure Storage Account
            $Username = $DomainJoinUserPrincipalName
            $Password = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
            [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

            # Creates a password for the Azure Storage Account in AD using the Kerberos key
            $ComputerPassword = ConvertTo-SecureString -String $Key.Replace("'","") -AsPlainText -Force
            Write-Log -Message "Secure string conversion succeeded" -Type 'INFO'

            # Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
            $SPN = 'cifs/' + $StorageAccountName + $Suffix

            # Create the Description value for the Azure Storage Account; attribute for computer object in AD 
            $Description = "Computer account object for Azure storage account $($StorageAccountName)."

            # Create the AD computer object for the Azure Storage Account
            $Computer = Get-ADComputer -Credential $Credential -Filter {Name -eq $StorageAccountName}
            if($Computer)
            {
                Remove-ADComputer -Credential $Credential -Identity $StorageAccountName -Confirm:$false
            }
            New-ADComputer -Credential $Credential -Name $StorageAccountName -Path $OuPath -ServicePrincipalNames $SPN -AccountPassword $ComputerPassword -KerberosEncryptionType $KerberosEncryptionType -Description $Description
            Write-Log -Message "Computer object creation succeeded" -Type 'INFO'

            # Get domain 'INFO' required for the Azure Storage Account
            $Domain = Get-ADDomain -Credential $Credential -Current 'LocalComputer'
            Write-Log -Message "Domain 'INFO' collection succeeded" -Type 'INFO'

            # Get the SID for the Azure Storage Account Computer Object in AD
            $ComputerSid = (Get-ADComputer -Credential $Credential -Identity $StorageAccountName).SID.Value
            Write-Log -Message "Computer object 'INFO' collection succeeded" -Type 'INFO'

            # Update the Azure Storage Account with the domain join 'INFO'
            Set-AzStorageAccount `
                -ResourceGroupName $StorageAccountResourceGroupName `
                -Name $StorageAccountName `
                -EnableActiveDirectoryDomainServicesForFile $true `
                -ActiveDirectoryDomainName $Domain.DNSRoot `
                -ActiveDirectoryNetBiosDomainName $Domain.NetBIOSName `
                -ActiveDirectoryForestName $Domain.Forest `
                -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
                -ActiveDirectoryDomainsid $Domain.DomainSID `
                -ActiveDirectoryAzureStorageSid $ComputerSid
            Write-Log -Message "Storage Account update with domain join info succeeded" -Type 'INFO'
        
            # Enable AES256 encryption if selected
            if($KerberosEncryptionType -eq 'AES256')
            {
                # Set the Kerberos encryption on the computer object
                $DistinguishedName = 'CN=' + $StorageAccountName + ',' + $OuPath
                Set-ADComputer -Credential $Credential -Identity $DistinguishedName -KerberosEncryptionType 'AES256'
                Write-Log -Message "Setting Kerberos AES256 Encryption on the computer object succeeded" -Type 'INFO'
                
                # Reset the Kerberos key on the Storage Account
                New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1
                $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
                Write-Log -Message "Resetting the Kerberos key on the Storage Account succeeded" -Type 'INFO'
            
                # Update the password on the computer object with the new Kerberos key on the Storage Account
                $NewPassword = ConvertTo-SecureString -String $Key -AsPlainText -Force
                Set-ADAccountPassword -Credential $Credential -Identity $DistinguishedName -Reset -NewPassword $NewPassword
                Write-Log -Message "Setting the new Kerberos key on the Computer Object succeeded" -Type 'INFO'
            }
        }

        # Get Storage Account key
        $StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName)[0].Value
        Write-Log -Message "The GET operation for the Storage Account key on $StorageAccountName succeeded" -Type 'INFO'

        # Set the variables required to mount the Azure file share
        $Group = $Netbios + '\' + $SecurityGroupName
        $Username = 'Azure\' + $StorageAccountName
        $Password = ConvertTo-SecureString -String "$($StorageKey)" -AsPlainText -Force
        [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

        $Context = (Get-AzStorageAccount -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName).Context
        $Shares = (Get-AzStorageShare -Context $Context).Name
        foreach($Share in $Shares)
        {
            # Mount file share
            $FileShare = '\\' + $StorageAccountName + $FilesSuffix + '\' + $Share
            New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential -Persist
            Write-Log -Message "Mounting the Azure file share, $FileShare, succeeded" -Type 'INFO'

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
            Write-Log -Message "Unmounting the Azure file share, $FileShare, succeeded" -Type 'INFO'
        }
    }

    Disconnect-AzAccount
    Write-Log -Message "Disconnection to Azure succeeded" -Type 'INFO'
}
catch {
    Write-Log -Message $_ -Type 'ERROR'
    $ErrorData = $_ | Select-Object *
    $ErrorData | Out-File -FilePath 'C:\cse.txt' -Append
    throw
}