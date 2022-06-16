param(
    $ImagePublisher,
    $ImageOffer,
    $ImageSku
)

$Terms = Get-AzMarketplaceTerms -Publisher $ImagePublisher -Product $ImageOffer -Name $ImageSku
if(!($Terms).Accepted)
{
    Set-AzMarketplaceTerms -InputObject $Terms -Reject | Out-Null
}