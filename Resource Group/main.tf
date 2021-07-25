terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "=2.46.0"
        }
    }
}

resource "azurerm_resource_group" "resource" {
    name     = "Resource_1"
    location = "West Europe"
}