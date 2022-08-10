param Environment string
param ImageDefinitionName string
param ImageOffer string
param ImagePublisher string
param ImageSku string
param Location string
param LocationShortName string


resource gallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: 'cg_aib_${Environment}_${LocationShortName}'
  location: Location
}

resource image 'Microsoft.Compute/galleries/images@2022-01-03' = {
  parent: gallery
  name: ImageDefinitionName
  location: Location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: contains(ImageSku, '-g2') ? 'V2' : 'V1'
    identifier: {
      publisher: ImagePublisher
      offer: ImageOffer
      sku: ImageSku
    }
  }
}


output ImageDefinitionResourceId string = image.id
