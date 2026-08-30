resource "azurerm_resource_group" "techsprint" {
  name     = var.resource_group_name
  location = var.location
}
