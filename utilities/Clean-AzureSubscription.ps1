# Remove Azure AD Users after removal of AD Connect



# Remove Azure AD Groups after removal of AD Connect
$Groups = @(
    'ADSyncAdmins',
    'ADSyncBrowse',
    'ADSyncOperators',
    'ADSyncPasswordSet',
    'DnsAdmins',
    'DnsUpdateProxy'
)