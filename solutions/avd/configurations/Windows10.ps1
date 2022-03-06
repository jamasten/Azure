configuration Windows10
{
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.10.1
    Import-DscResource -ModuleName SecurityPolicyDsc -ModuleVersion 2.10.0.0

    Node localhost
    {
        Edge STIG_MicrosoftEdge
        {

        }

        InternetExplorer STIG_IE11
        {
            BrowserVersion = '11'
            SkipRule       = 'V-46477'
        }

        DotNetFramework STIG_DotnetFramework
        {
            FrameworkVersion = '4'
        }

        WindowsFirewall STIG_WindowsFirewall
        {
            Skiprule = @('V-17443', 'V-17442')
        }

        WindowsDefender STIG_WindowsDefender
        {
            OrgSettings = @{
                'V-213450' = @{ValueData = '1' }
            }
        }

        WindowsClient STIG_WindowsClient
        {
            OsVersion   = '10'
            # V-220805 breaks connectivity to the AVD Session Host
            SkipRule    = @("V-220740","V-220739","V-220741", "V-220908", "V-220805")
            Exception   = @{
                'V-220972' = @{
                    Identity = 'Guests'
                }
                'V-220968' = @{
                    Identity = 'Guests'
                }
                'V-220969' = @{
                    Identity = 'Guests'
                }
                'V-220971' = @{
                    Identity = 'Guests'
                }
            }
            OrgSettings =  @{
                'V-220912' = @{
                    OptionValue = 'xGuest'
                }
            }
        }

        AccountPolicy BaseLine2
        {
            Name                                = "Windows10fix"
            Account_lockout_threshold           = 3
            Account_lockout_duration            = 15
            Reset_account_lockout_counter_after = 15
        }

        $office = Get-WmiObject win32_product | Where-Object {$_.Name -like "Office 16*"}

        if($office){
            Office STIG_Office365
            {
                OfficeApp = '365ProPlus'
            }
        }
    }
}