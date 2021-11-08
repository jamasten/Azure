

The code in this repository is forked from [this](https://github.com/jamasten/Azure) repository managed from jamasten.  The upstream repository is fairly active and is merged in frequently.

To allow for this repository to be moduled in from other terraform modules the main entry point has been wrapped up in a terraform main.tf file.  There are many parameters, all should have description in main.tf, that can be passed in but most are defaulted.  Below is an example for the battelledev.onmicrosoft.us tenant including the parameters that are not defaulted. 

`terraform apply -var='domain_name=battelledev.onmicrosoft.us' -var='dc_admins_group_object_id=0b2cecb7-2c4e-41a2-b6c9-a10c0568a373' -var='wvd_object_id=2a0d5980-c27d-4353-ad5c-f04728028a13' -var='resource_name_suffix=mvdev2' -var='ou_path=OU=AADDC Computers,DC=battelledev,DC=onmicrosoft,DC=us' -var='subnet=gold-wookie-dev' -var='virtual_network=gold-wookie-dev' -var='virtual_network_resource_group=gold-wookie-dev`

Once an azure workspace is deployed it can be connected to via the [Windows Desktop client](https://docs.microsoft.com/en-us/azure/virtual-desktop/user-documentation/connect-windows-7-10).

# Azure

The code in this repository is code that I developed and use to:

## Directories

* **solutions**: test customer scenarios & develop solutions around specific pain points
* **subscription**: deploy my lab containing core infrastructure & services to support my solutions
* **utilities**: solve problems around governance and management

