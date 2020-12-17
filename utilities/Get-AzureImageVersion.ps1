$locName="usgovarizona"
$pubName="cisco"
$offerName="cisco-ftdv"
Get-AzVMImagePublisher -Location $locName
Get-AzVMImageOffer -Location $locName -PublisherName $pubName
Get-AzVMImageSku -Location $locName -PublisherName $pubName -Offer $offerName | Select Skus

$locName="southafricanorth"
$pubName="MicrosoftWindowsServer"
$offerName="WindowsServer"
$skuName="ftdv-azure-byol"
Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Skus $skuname | select Version