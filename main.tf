provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_subscription_template_deployment" "avd" {
    name = "advmvdev"
    location = "usgovvirginia"
    template_content = file("./solutions/avd/solution.json")
    parameters_content = file("./parameters/test-parameters-valerio.json")
}