terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

## Azure Foundation Resources ##
# -----------------------------

resource "azurerm_resource_group" "example" {
  name     = "example-resources1"
  # Best practice: use lowercase for Azure locations
  location = "eastus" 
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example_pip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static" # Standard SKU requires Static allocation
  
  # 👇 ADD THESE TWO LINES TO FIX THE LIMIT ERROR
  sku                 = "Standard"
  sku_tier            = "Regional" 
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

# -----------------------------
## Azure Linux Virtual Machine ##
# -----------------------------

resource "azurerm_linux_virtual_machine" "example" {
  name                  = "example-machine"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  # SSH Key Configuration (Best Practice)
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/SREE/.ssh/id_rsa.pub")
  }
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}