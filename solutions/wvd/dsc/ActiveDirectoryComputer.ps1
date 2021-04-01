configuration ActiveDirectoryComputer
   param 
   ( 
        [Parameter(Mandatory=$true)]
        [String]$DomainName,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainCreds,

        [Parameter(Mandatory=$true)]
        [String]$Environment,

        [Parameter(Mandatory=$true)]
        [String]$StorageAccountName
    )
    
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion '4.2.0.0'
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'

    $Suffix = switch($Environment)
    {
        AzureCloud {'.file.core.windows.net'}
        AzureUSGovernment {'.file.core.usgovcloudapi.net'}
    }
    $SPN = 'cifs/' + $StorageAccountName + $Suffix
    $Description = "Computer account object for Azure storage account $($StorageAccountName)."

    Node localhost
    {
        ADComputer 'StorageAccount'
        {
            ComputerName            = $StorageAccountName
            Path                    = $OuPath
            Credential              = $Credential
            ServicePrincipalNames   = $SPN
            Description             = $Description
        }
    }
}