$location = 'eastus'
$publisher = 'MicrosoftWindowsDesktop'
#$publisher = 'MicrosoftWindowsServer'
#$offer = 'WindowsServer'
$offer = 'office-365'
#$offer = 'windows-evd'
#$offer = 'Windows-10'
#$sku = '2019-Datacenter-Core'
#$sku = '21h1-evd-o365pp'
$sku = 'win11-21h2-avd-m365'
(Get-AzVMImagePublisher -Location $location).PublisherName
(Get-AzVMImageOffer -Location $location -PublisherName $publisher).Offer
(Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer).Skus
Get-AzVMImage -Location $location -PublisherName $publisher -Offer $offer -Skus $sku | Select-Object * | Format-List