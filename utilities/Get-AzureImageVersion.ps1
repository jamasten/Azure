$location = "eastus"
$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2019-Datacenter-Core"
(Get-AzVMImagePublisher -Location $location).PublisherName
(Get-AzVMImageOffer -Location $location -PublisherName $publisher).Offer
(Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer).Skus
Get-AzVMImage -Location $location -PublisherName $publisher -Offer $offer -Skus $sku | Select-Object * | Format-List