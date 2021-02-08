configuration DnsForwarders 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$Domain,

        [Parameter(Mandatory)]
        [Array]$IPAddresses
    ) 
    
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName xDnsServer -ModuleVersion '1.16.0.0'

    $DomainCreds = Get-AutomationPSCredential 'Administrator'

    Node localhost
    {

        WindowsFeature DnsServer
	    {
	        Ensure = "Present"
            Name = "DNS"
	    }

        WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DnsServer"
	    }
         
        xDnsServerConditionalForwarder AzurePrivateDnsZone
        {
            Ensure = "Present"
            Name = "core.windows.net"
            MasterServers = "168.63.129.16"
            DependsOn = "[WindowsFeature]DnsServer"
        }

        xDnsServerConditionalForwarder OnPremDns
        {
            Ensure = "Present"
            Name = $Domain
            MasterServers = $IPAddresses
            DependsOn = "[WindowsFeature]DnsServer"
        }


    }
}