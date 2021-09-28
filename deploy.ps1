# =====================================
# can not get this to work so moving on
# =====================================
# $jsonParams = @"
# {
#     "DomainName": {"value": "battelle.us"},
#     "DomainServices": { "value": "AzureActiveDirectory" },
#     "DomainJoinUserPrincipalName": { "value": "valerio@battelle.us" },
#     "EphemeralOsDisk": { "value": false },
#     "OuPath": { "value": "OU=AADDC Computers,DC=battelle,DC=us" },
#     "ResourceNameSuffix": { "value": "avddev3" },
#     "SecurityPrincipalId": { "value": "8d8e9837-ab22-4de6-9d6d-7768195c6444" },
#     "SecurityPrincipalName": { "value": "avd_users" },
#     "Subnet": { "value": "avd-dev" },
#     "VirtualNetwork": { "value": "avd-dev" },
#     "VirtualNetworkResourceGroup": { "value": "avd-dev" },
#     "SessionHostCount": { "value": 5 },
#     "VmPassword": { "value": "aaAA11223344" },
#     "VmUsername": { "value": "azadmin" },
#     "WvdObjectId": { "value": "55c182d1-9935-4ed7-a448-5d453e52e2ed" },
#     "Tags": { "value": {"Owner": "CUBE", "Purpose": "POC", "Environment": "Dev"} },
#     "RecoveryServices": { "value": false },
#     "ImageSku": {"value": "20h2-ent-cpc-m365-g2"},
#     "ImageOffer": {"value": "windows-ent-cpc"}
# }
# "@

# $jsonObject = $jsonParams | ConvertFrom-Json
# az deployment sub create --location usgovvirginia --template-file .\solutions\avd\solution.json `
# --parameters $jsonObject

# ==================================
# this works but not but still ugly
# ===================================
# $jsonParams = @"
# {\"DomainName\": { \"value\": \"battelle.us\" },\"DomainServices\": { \"value\": \"AzureActiveDirectory\" }, \"DomainJoinUserPrincipalName\": { \"value\": \"valerio@battelle.us\" }, \"EphemeralOsDisk\": { \"value\": false }, \"OuPath\": { \"value\": \"OU=AADDC Computers,DC=battelle,DC=us\" }, \"ResourceNameSuffix\": { \"value\": \"avddev3\" }, \"SecurityPrincipalId\": { \"value\": \"8d8e9837-ab22-4de6-9d6d-7768195c6444\" }, \"SecurityPrincipalName\": { \"value\": \"avd_users\" }, \"Subnet\": { \"value\": \"avd-dev\" }, \"VirtualNetwork\": { \"value\": \"avd-dev\" }, \"VirtualNetworkResourceGroup\": { \"value\": \"avd-dev\" }, \"SessionHostCount\": { \"value\": 5 },\"VmPassword\": { \"value\": \"aaAA11223344\" }, \"VmUsername\": { \"value\": \"azadmin\" }, \"WvdObjectId\": { \"value\": \"55c182d1-9935-4ed7-a448-5d453e52e2ed\" }, \"Tags\": { \"value\": {\"Owner\": \"Matt Valerio\", \"Purpose\": \"POC\", \"Environment\": \"Dev\"} }, \"RecoveryServices\": { \"value\": false }, \"ImageSku\": {\"value\": \"20h2-ent-cpc-m365-g2\"}, \"ImageOffer\": {\"value\": \"windows-ent-cpc\"} }
# "@

# az deployment sub create --location usgovvirginia --template-file .\solutions\avd\solution.json `
# --parameters $jsonParams

# =====================================
# punting on making this pretty for now
# =====================================
az deployment sub create --location usgovvirginia --template-file .\solutions\avd\solution.json `
  --parameters '{\"DomainName\": { \"value\": \"battelle.us\" },\"DomainServices\": { \"value\": \"AzureActiveDirectory\" }, \"DomainJoinUserPrincipalName\": { \"value\": \"valerio@battelle.us\" }, \"EphemeralOsDisk\": { \"value\": false }, \"OuPath\": { \"value\": \"OU=AADDC Computers,DC=battelle,DC=us\" }, \"ResourceNameSuffix\": { \"value\": \"avddev3\" }, \"SecurityPrincipalId\": { \"value\": \"8d8e9837-ab22-4de6-9d6d-7768195c6444\" }, \"SecurityPrincipalName\": { \"value\": \"avd_users\" }, \"Subnet\": { \"value\": \"avd-dev\" }, \"VirtualNetwork\": { \"value\": \"avd-dev\" }, \"VirtualNetworkResourceGroup\": { \"value\": \"avd-dev\" }, \"SessionHostCount\": { \"value\": 5 },\"VmPassword\": { \"value\": \"aaAA11223344\" }, \"VmUsername\": { \"value\": \"azadmin\" }, \"WvdObjectId\": { \"value\": \"55c182d1-9935-4ed7-a448-5d453e52e2ed\" }, \"Tags\": { \"value\": {\"Owner\": \"Matt Valerio\", \"Purpose\": \"POC\", \"Environment\": \"Dev\"} }, \"RecoveryServices\": { \"value\": false }, \"ImageSku\": {\"value\": \"20h2-ent-cpc-m365-g2\"}, \"ImageOffer\": {\"value\": \"windows-ent-cpc\"} }'