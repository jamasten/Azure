$location = 'eastus'
#$location = 'usgovvirginia'

$publisher = 'MicrosoftWindowsDesktop'
#$publisher = 'MicrosoftWindowsServer'

$offer = 'office-365'
#$offer = 'Windows-11'
#$offer = 'Windows-10'
#$offer = 'WindowsServer'

$sku = 'win11-21h2-avd-m365'
#$sku = '21h1-evd-o365pp'
#$sku = '2019-Datacenter-Core'

(Get-AzVMImagePublisher -Location $location).PublisherName

(Get-AzVMImageOffer -Location $location -PublisherName $publisher).Offer

(Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer).Skus

Get-AzVMImage -Location $location -PublisherName $publisher -Offer $offer -Skus $sku | Select-Object * | Format-List