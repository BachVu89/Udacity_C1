terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Define resource group that already created in packer
data "azurerm_resource_group" "rg" {
  name     = var.packer_resource_group
}

# Create new virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet4"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Create new subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet4"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create new public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create new network security group
resource "azurerm_network_security_group" "my_nsg" {
  name                = "my_nsg4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = {
    project = "udacity_devops"
    createdBy= "bachvh"
  }
}

# Create new security rules
resource "azurerm_network_security_rule" "DenyAllInbound" {
    name                         = "DenyAllInbound"
    description                  = "This rule with low priority deny all the inbound traffic"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Deny"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "*"
    destination_address_prefix   = "*"
    resource_group_name          = data.azurerm_resource_group.rg.name
    network_security_group_name  = azurerm_network_security_group.my_nsg.name
}

resource "azurerm_network_security_rule" "AllowInboundSameVirtualNetwork" {
    name                         = "AllowInboundSameVirtualNetwork"
    description                  = "Allow inbound traffick inside the same Virtual Network"
    priority                     = 101
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_ranges           = ["80", "443"]
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "VirtualNetwork"
    destination_address_prefix   = "VirtualNetwork"
    resource_group_name          = data.azurerm_resource_group.rg.name
    network_security_group_name  = azurerm_network_security_group.my_nsg.name
}

resource "azurerm_network_security_rule" "AllowOutboundSameVirtualNetwork" {
    name                         = "AllowOutboundSameVirtualNetwork"
    description                  = "Allow outbound traffick inside the same Virtual Network"
    priority                     = 102
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_ranges           = ["80", "443"]
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "VirtualNetwork"
    destination_address_prefix   = "VirtualNetwork"
    resource_group_name          = data.azurerm_resource_group.rg.name
    network_security_group_name  = azurerm_network_security_group.my_nsg.name
}

resource "azurerm_network_security_rule" "AllowHTTPTrafficFromLoadBalancer" {
    name                         = "AllowHTTPTrafficFromLoadBalancer"
    description                  = "Allow HTTP traffic to the VMs from the load balancer."
    priority                     = 103
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_ranges           = ["80", "443"]
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "AzureLoadBalancer"
    destination_address_prefix   = "VirtualNetwork"
    resource_group_name          = data.azurerm_resource_group.rg.name
    network_security_group_name  = azurerm_network_security_group.my_nsg.name
}


# Create new network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  count               = var.vm_count
  name                = "myNIC-4-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    primary                       = true
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "my_security_group_association" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.my_terraform_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID when a new resource group is defined
    resource_group = data.azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create new (and display) an SSH key
resource "tls_private_key" "my_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create new load balancer
resource "azurerm_lb" "my_azurerm_lb" {
  name                = "my_azurerm_lb4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# The load balancer will use this backend pool
resource "azurerm_lb_backend_address_pool" "my_lb_backend_address_pool" {
  loadbalancer_id     = azurerm_lb.my_azurerm_lb.id
  name                = "my_lb_backend_address_pool4"
}

# Associate the LB with the backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "my_network_interface_backend_address_pool_association" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.my_terraform_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.my_lb_backend_address_pool.id
}

# Create new virtual machine availability set
resource "azurerm_availability_set" "my_availability_set" {
  name                = "my_availability_set4"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = {
    project = "udacity-devops"
    createdBy= "bachvh"
  }
}

# Created new image from packer
data "azurerm_image" "vm_ubuntu_1804" {
  name                = "Image_bachVH"
  resource_group_name = var.packer_resource_group
}

# Create new virtual machines
resource "azurerm_linux_virtual_machine" "my_linux_virtual_machine" {
  count                           = var.vm_count
  name                            = "vm-ubuntu-1804-4-${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_DS2_v2"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [element(azurerm_network_interface.my_terraform_nic.*.id, count.index)]
  availability_set_id = azurerm_availability_set.my_availability_set.id

  source_image_id = data.azurerm_image.vm_ubuntu_1804.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    project = "udacity_devops"
    createdBy= "bachvh"
  }
}

# create a virtual disk for each VM created.
resource "azurerm_managed_disk" "my_managed_disk" {
  count                           = var.vm_count
  name                            = "data-disk-4-${count.index}"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  storage_account_type            = "Standard_LRS"
  create_option                   = "Empty"
  disk_size_gb                    = 1
}
resource "azurerm_virtual_machine_data_disk_attachment" "my_virtual_machine_data_disk_attachment" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.my_managed_disk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.my_linux_virtual_machine.*.id[count.index]
  lun                = 10 * count.index
  caching            = "ReadWrite"
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "public_ip_address_1" {
  value = azurerm_linux_virtual_machine.my_linux_virtual_machine[0].public_ip_address
}

output "public_ip_address_2" {
  value = azurerm_linux_virtual_machine.my_linux_virtual_machine[1].public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.my_ssh.private_key_pem
  sensitive = true
}