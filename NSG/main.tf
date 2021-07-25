terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "=2.46.0"
        }
    }
}

data "azurerm_resource_group" "resource" {
    name = "Resource_1"
}

resource "azurerm_network_security_group" "Network_Security_Group" {
    name                = "NSG_1"
    location            = data.azurerm_resource_group.resource.location
    resource_group_name = data.azurerm_resource_group.resource.name

    security_rule {
        name                       = "rule_1"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Production"
    }
}
