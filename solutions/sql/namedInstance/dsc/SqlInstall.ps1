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

        Script ForceReboot
        {
            TestScript = {
                $false
            }
            SetScript = {
                $global:DSCMachineStatus = 1 
            }
            GetScript = { return @{result = 'result'}}
        }

        PendingReboot PostSqlUninstall
        {
            Name = 'RebootPostSqlInstall'
            DependsOn = '[Script]ForceReboot'
        }

        WindowsFeature 'NetFramework45'
        {
            Name = 'NET-Framework-45-Core'
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