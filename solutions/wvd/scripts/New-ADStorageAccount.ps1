param 
( 
    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [String]$Key,

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

$Test = Get-ADComputer -Identity $StorageAccountName -ErrorAction Ignore
if(!$Test)
{
    try
    {
        if(!$OuPath)
        {
            New-ADComputer `
                -Name $StorageAccountName `
                -ServicePrincipalNames $SPN `
                -AccountPassword $Password `
                -KerberosEncryptionType $KerberosEncryptionType `
                -Description $Description `
                -ErrorAction Stop
        } 
        else 
        {
            New-ADComputer `
                -Name $StorageAccountName `
                -ServicePrincipalNames $SPN `
                -AccountPassword $Password `
                -KerberosEncryptionType $KerberosEncryptionType `
                -Description $Description `
                -Path $OuPath `
                -ErrorAction Stop
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