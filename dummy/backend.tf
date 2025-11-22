terraform {
  backend "azurerm" {
    storage_account_name = "azurebackendstoragesree"
    container_name = "backend"
    key = "terraform.tfstate"
    access_key = ""
  }
}