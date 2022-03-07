configuration DnsForwarders 
{ 
   param
   ( 
        [Parameter(Mandatory)]
        [Array]$IPAddresses
    ) 
    
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName xDnsServer -ModuleVersion '1.16.0.0'

    Node localhost
    {

        WindowsFeature DnsServer
	    {
	        Ensure = "Present"
            Name = "DNS"
	    }

        xDnsServerForwarder OnPremDns
        {
            IsSingleInstance = 'Yes'
            IPAddresses = $IPAddresses
            UseRootHint = $true
            DependsOn = "[WindowsFeature]DnsServer"
        }

        xDnsServerConditionalForwarder AzurePrivateDnsZone
        {
            Ensure = "Present"
            Name = "core.windows.net"
            MasterServers = "168.63.129.16"
            DependsOn = "[WindowsFeature]DnsServer"
        }
    }
}