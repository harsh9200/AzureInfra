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


data "azurerm_resource_group" "resource" {
    name = "Resource_1"
}


data "azurerm_network_security_group" "Network_Security_Group" {
    name                = "NSG_1"
    resource_group_name = data.azurerm_resource_group.resource.name
}


resource "azurerm_network_ddos_protection_plan" "DDOS_Plan" {
    name                = "DDOS_Plan_1"
    location            = data.azurerm_resource_group.resource.location
    resource_group_name = data.azurerm_resource_group.resource.name
}


resource "azurerm_virtual_network" "example" {
    name                = "virtualNetwork1"
    location            = data.azurerm_resource_group.resource.location
    resource_group_name = data.azurerm_resource_group.resource.name
    address_space       = ["10.0.0.0/16"]
    dns_servers         = ["10.0.0.4", "10.0.0.5"]

    ddos_protection_plan {
        id     = azurerm_network_ddos_protection_plan.DDOS_Plan.id
        enable = true
    }

    subnet {
        name           = "subnet1"
        address_prefix = "10.0.1.0/24"
    }

    subnet {
        name           = "subnet2"
        address_prefix = "10.0.2.0/24"
    }

    subnet {
        name           = "subnet3"
        address_prefix = "10.0.3.0/24"
        security_group = data.azurerm_network_security_group.Network_Security_Group.id
    }

    tags = {
        environment = "Production"
    }
}