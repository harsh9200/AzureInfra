terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "=2.46.0"
        }
    }
}

provider "azurerm" {
    features {}
}

#? Create Resource Group
resource "azurerm_resource_group" "resource" {
    name     = "test_resource"
    location = "West Europe"
}

#? Virtual Network
resource "azurerm_virtual_network" "v_net" {
    name                = "test_vnet"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location
    address_space       = ["10.0.0.0/16"]
}

#? Subnet 1
resource "azurerm_subnet" "subnet_1" {
    name                 = "public-lb-subnet"
    resource_group_name  = azurerm_resource_group.resource.name
    virtual_network_name = azurerm_virtual_network.v_net.name
    address_prefixes     = ["10.0.1.0/24"]
}

#? Subnet 2
resource "azurerm_subnet" "subnet_2" {
    name                 = "public-bastion-subnet"
    resource_group_name  = azurerm_resource_group.resource.name
    virtual_network_name = azurerm_virtual_network.v_net.name
    address_prefixes     = ["10.0.2.0/24"]
}

#? Subnet 3
resource "azurerm_subnet" "subnet_3" {
    name                 = "private-vm-subnet"
    resource_group_name  = azurerm_resource_group.resource.name
    virtual_network_name = azurerm_virtual_network.v_net.name
    address_prefixes     = ["10.0.3.0/24"]
}

#? Subnet 4
resource "azurerm_subnet" "subnet_4" {
    name                 = "private-db-subnet"
    resource_group_name  = azurerm_resource_group.resource.name
    virtual_network_name = azurerm_virtual_network.v_net.name
    address_prefixes     = ["10.0.4.0/24"]
}


#?##########################################################################
#?#########################  TEST-BASTION-VM  ##############################
#?##########################################################################

#? Public IP
resource "azurerm_public_ip" "bastion_public_ip" {
    name                = "bastion-public-ip"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location
    allocation_method   = "Static"
}

#? Network Security Group
resource "azurerm_network_security_group" "test_bastion_vm_nsg" {
    name                = "test-bastion-vm-nsg"
    location            = azurerm_resource_group.resource.location
    resource_group_name = azurerm_resource_group.resource.name

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

#? Network Interface
resource "azurerm_network_interface" "test_bastion_nic" {
    name                = "test-bastion-nic"
    location            = azurerm_resource_group.resource.location
    resource_group_name = azurerm_resource_group.resource.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subnet_2.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
    }
}

#? Network Security Group Associated with Network Interface
resource "azurerm_network_interface_security_group_association" "test_bastion_association" {
    network_interface_id      = azurerm_network_interface.test_bastion_nic.id
    network_security_group_id = azurerm_network_security_group.test_bastion_vm_nsg.id
}

#? Virtual Machine
resource "azurerm_linux_virtual_machine" "test_bastion_vm" {
    name                = "test-bastion-vm"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location
    size                = "Standard_F2"
    admin_username      = "azureuser"
    network_interface_ids = [
        azurerm_network_interface.test_bastion_nic.id,
    ]

    admin_ssh_key {
        username   = "azureuser"
        public_key = file("id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }
}




#?##########################################################################
#?#####################  APP VIRTUAL MACHINE  ##############################
#?##########################################################################


#? Network Security Group
resource "azurerm_network_security_group" "app_vm_nsg" {
    name                = "app-vm-nsg"
    location            = azurerm_resource_group.resource.location
    resource_group_name = azurerm_resource_group.resource.name

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

#? Network Interface
resource "azurerm_network_interface" "app_vm_nic" {
    name                = "app-vm-nic"
    location            = azurerm_resource_group.resource.location
    resource_group_name = azurerm_resource_group.resource.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subnet_3.id
        private_ip_address_allocation = "Dynamic"
    }
}

#? Network Security Group Associated with Network Interface
resource "azurerm_network_interface_security_group_association" "app_vm_association" {
    network_interface_id      = azurerm_network_interface.app_vm_nic.id
    network_security_group_id = azurerm_network_security_group.app_vm_nsg.id
}


#? Virtual Machine
resource "azurerm_linux_virtual_machine" "app_vm" {
    name                = "app-vm"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location
    size                = "Standard_F2"
    admin_username      = "azureuser"
    network_interface_ids = [
        azurerm_network_interface.app_vm_nic.id,
    ]

    admin_ssh_key {
        username   = "azureuser"
        public_key = file("id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "StandardSSD_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }
}




#?##########################################################################
#?########################  APPLICATION GATEWAY  ###########################
#?##########################################################################



#? Public IP
resource "azurerm_public_ip" "app_gateway_public_ip" {
    name                = "app-gateway-public-ip"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location
    allocation_method   = "Dynamic"
}


#? Application Gateway
resource "azurerm_application_gateway" "test_app_gateway" {
    name                = "test-app-gateway"
    resource_group_name = azurerm_resource_group.resource.name
    location            = azurerm_resource_group.resource.location

    sku {
        name     = "Standard_Small"
        tier     = "Standard"
        capacity = 2
    }

    gateway_ip_configuration {
        name      = "my-gateway-ip-configuration"
        subnet_id = azurerm_subnet.subnet_1.id
    }

    frontend_port {
        name = "HTTP-Frontend-Port"
        port = 80
    }

    frontend_ip_configuration {
        name                 = "Frontend-Public-IP"
        public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
    }

    backend_address_pool {
        name = "Backend-Address-Pool"
    }

    backend_http_settings {
        name                  = "HTTP-Setting"
        cookie_based_affinity = "Disabled"
        path                  = "/path1/"
        port                  = 80
        protocol              = "Http"
        request_timeout       = 60
    }

    http_listener {
        name                           = "HTTP-Listener"
        frontend_ip_configuration_name = "Frontend-Public-IP"
        frontend_port_name             = "HTTP-Frontend-Port"
        protocol                       = "Http"
    }

    request_routing_rule {
        name                       = "Routing-Rule"
        rule_type                  = "Basic"
        http_listener_name         = "HTTP-Listener"
        backend_address_pool_name  = "Backend-Address-Pool"
        backend_http_settings_name = "HTTP-Setting"
    }
}


resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "test" {
    ip_configuration_name   = "internal"
    network_interface_id    = azurerm_network_interface.app_vm_nic.id
    backend_address_pool_id = azurerm_application_gateway.test_app_gateway.backend_address_pool.0.id
}
