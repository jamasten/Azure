# The purpose of this script is to generate all VM Sku's in JSON format
# to be used in an ARM template for an "allowed values" array in a parameter

$Regions = (Get-AzLocation).Location
$AllSizeData = @()
foreach($Region in $Regions)
{
    $AllSizeData += (Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue).Name
}

$FilteredData = $AllSizeData | Select-Object -Unique | sort
$FormattedData = @()
foreach($Size in $FilteredData)
{
    $FormattedData += '"' + $Size + '",'
}

$FormattedData