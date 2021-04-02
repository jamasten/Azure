param 
( 
    [Parameter(Mandatory)]
    [String]$DomainAdminPassword,    
    
    [Parameter(Mandatory)]
    [String]$DomainAdminUsername,

    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [String]$Key,

    [Parameter(Mandatory)]
    [String]$Netbios,

    [Parameter(Mandatory=$false)]
    [String]$OuPath,

    [Parameter(Mandatory)]
    [String]$StorageAccountName
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
        New-Item -Path C:\ -Name cse.log
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

$Username = $Netbios + '\' + $DomainAdminUsername
$Password = ConvertTo-SecureString -String $DomainAdminPassword -AsPlainText -Force
[pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($Username, $DomainAdminPassword)

$Suffix = switch($Environment)
{
    AzureCloud {'.file.core.windows.net'}
    AzureUSGovernment {'.file.core.usgovcloudapi.net'}
}
Write-Log -Message "Storage Account Suffix = $Suffix" -Type INFO

$Password = ConvertTo-SecureString -String $Key -AsPlainText -Force -ErrorAction Stop
Write-Log -Message "Secure string conversion succeeded" -Type INFO

$SPN = 'cifs/' + $StorageAccountName + $Suffix

$Description = "Computer account object for Azure storage account $($StorageAccountName)."

$Test = Get-ADComputer -Filter {Name -eq $StorageAccountName}
if(!$Test)
{
    try
    {
        if(!$OuPath)
        {
            Invoke-Command -Credential $Credential -ScriptBlock {
                New-ADComputer `
                    -Name $Using:StorageAccountName `
                    -ServicePrincipalNames $Using:SPN `
                    -AccountPassword $Using:Password `
                    -KerberosEncryptionType $Using:KerberosEncryptionType `
                    -Description $Using:Description `
                    -ErrorAction Stop
            }
        } 
        else 
        {
            Invoke-Command -Credential $Credential -ScriptBlock {
                New-ADComputer `
                    -Name $Using:StorageAccountName `
                    -ServicePrincipalNames $Using:SPN `
                    -AccountPassword $Using:Password `
                    -KerberosEncryptionType $Using:KerberosEncryptionType `
                    -Description $Using:Description `
                    -Path $Using:OuPath `
                    -ErrorAction Stop
            }
        }
        Write-Log -Message "Computer object creation succeeded" -Type INFO
    }
    catch
    {
        Write-Log -Message "Failed to create computer object" -Type ERROR
        $String = $_ | Select-Object * | Out-String
        Write-Log -Message $String -Type ERROR
        throw $_
    }
}

$Domain = Get-ADDomain -ErrorAction Stop
Write-Log -Message "Domain info collection succeeded" -Type INFO

$ComputerSid = (Get-ADComputer -Identity $StorageAccountName -ErrorAction Stop).SID.Value
Write-Log -Message "Computer object info collection succeeded" -Type INFO

$Output = ",$($Domain.ObjectGUID),$($Domain.DomainSID),$($ComputerSid),"
Write-Log -Message $Output -Type INFO
Write-Host $Output