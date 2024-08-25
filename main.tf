terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id != null ? var.azure_subscription_id : null
  tenant_id       = var.azure_tenant_id != null ? var.azure_tenant_id : null
  client_id       = var.azure_client_id != null ? var.azure_client_id : null
  client_secret   = var.azure_client_secret != null ? var.azure_client_secret : null
}


resource "azurerm_resource_group" "jupyter-lab-rg" {
  name     = "jupyter-lab-resources"
  location = var.resource_location
}

resource "azurerm_virtual_network" "jupterlab-vnet" {
  name                = "jupyter-lab-vn"
  resource_group_name = azurerm_resource_group.jupyter-lab-rg.name
  location            = azurerm_resource_group.jupyter-lab-rg.location
  address_space       = ["10.0.0.0/16"] # 255.255.0.0
}

resource "azurerm_subnet" "jupterlab-subnet" {
  name                 = "wg-subnet"
  resource_group_name  = azurerm_resource_group.jupyter-lab-rg.name
  virtual_network_name = azurerm_virtual_network.jupterlab-vnet.name
  address_prefixes     = ["10.0.0.0/24"] # 255.255.255.0
}

resource "azurerm_network_security_group" "jupterlab-securitygroup" {
  name                = "wg-nsg"
  resource_group_name = azurerm_resource_group.jupyter-lab-rg.name
  location            = azurerm_resource_group.jupyter-lab-rg.location
  security_rule {
    name                       = "AlljupterlabPorts"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "8888", "443", "4040","8000","8080"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "wg-subnet-nsg" {
  subnet_id                 = azurerm_subnet.jupterlab-subnet.id
  network_security_group_id = azurerm_network_security_group.jupterlab-securitygroup.id
}

resource "azurerm_public_ip" "jupterlab-publicip" {
  name                = "jupterlabip"
  resource_group_name = azurerm_resource_group.jupyter-lab-rg.name
  location            = azurerm_resource_group.jupyter-lab-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "jupterlab-ni" {
  name                = "jupterlab-ni"
  resource_group_name = azurerm_resource_group.jupyter-lab-rg.name
  location            = azurerm_resource_group.jupyter-lab-rg.location
  ip_configuration {
    name                          = "wg-ip-config"
    subnet_id                     = azurerm_subnet.jupterlab-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jupterlab-publicip.id
  }
}

resource "azurerm_linux_virtual_machine" "jupterlab-vm" {
  name                            = "jupterlab-vm"
  resource_group_name             = azurerm_resource_group.jupyter-lab-rg.name
  location                        = azurerm_resource_group.jupyter-lab-rg.location
  size                            = var.vm_size 
  admin_username                  = var.ssh_username
  admin_password                  = var.ssh_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.jupterlab-ni.id,
  ]

  admin_ssh_key {
    username   = var.ssh_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "jupterlab-os-disk"
    disk_size_gb         = 30
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  custom_data = base64encode(templatefile("scripts/jupyter_lab.sh", { jupyter_password = var.jupyter_password}))
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.jupterlab-vm.public_ip_address
}