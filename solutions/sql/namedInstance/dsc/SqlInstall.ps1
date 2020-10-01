Configuration SQLInstall
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

        PendingReboot PostSqlUninstall
        {
            Name       = 'RebootPostSqlInstall'
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
            DependsOn = '[PendingReboot]PostSqlUninstall'
        }

        SqlSetup 'InstallDefaultInstance'
        {
            InstanceName        = 'ABRACADABRA'
            Features            = 'SQLENGINE'
            SourcePath          = 'C:\SQLServerFull'
            SQLSysAdminAccounts = @('Administrators')
            DependsOn           = '[WindowsFeature]NetFramework45'
        }
    }
}