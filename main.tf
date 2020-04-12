provider "azurerm" {
  version = "~>2.0"
  features {}

  subscription_id = "aa196c2a-7ba7-4d69-a982-f94576d5f33c"
  client_id       = "7ef9954c-4ab8-4887-aa22-32731bc9843d"
  client_secret   = "aR.4HOYllX/4n50OrQMbP:D[mleeE0t5"
  tenant_id       = "52c57360-f738-4cd8-94f6-f03ce9acd99b"

}

resource "azurerm_resource_group" "web_server_rg" {
  name     = "web-rg"
  location = "westus2"
}