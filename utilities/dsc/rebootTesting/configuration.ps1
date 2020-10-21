Configuration Reboot
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

        Script SetReboot
        {
            TestScript = {
                $false
            }
            SetScript = {
                $global:DSCMachineStatus = 1 
            }
            GetScript = { return @{result = 'result'}}
        }

        PendingReboot Reboot
        {
            Name = 'RebootPostSqlInstall'
            DependsOn = '[Script]SetReboot'
        }
    }
}