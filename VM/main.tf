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


data "azurerm_subnet" "subnet" {
    name                 = "subnet1"
    virtual_network_name = "virtualNetwork1"
    resource_group_name  = data.azurerm_resource_group.resource.name
}


resource "azurerm_postgresql_server" "postgreSQL_server" {
    name                = "PostgreSQL_server_1"
    location            = "Australia East"
    resource_group_name = "PgResourceGroup"

    sku_name = "GP_Gen5_2"

    storage_profile {
        storage_mb            = 51200
        backup_retention_days = 7
        geo_redundant_backup  = "Disabled"
        auto_grow             = "Enabled"
    }

    administrator_login          = "psqladmin"
    administrator_login_password = "H@Sh1CoR3!"
    version                      = "11"
    ssl_enforcement              = "Enabled"
}


resource "azurerm_private_endpoint" "private_endpoint" {
    name                = "Private_Endpoint_1"
    location            = "Australia East"
    resource_group_name = "PgResourceGroup"
    subnet_id           = data.azurerm_subnet.subnet.id

    private_service_connection {
        name                           = "privateserviceconnection_1"
        private_connection_resource_id = azurerm_postgresql_server.postgreSQL_server.id
        subresource_names              = [ "postgresqlServer" ]
        is_manual_connection           = false
    }
}