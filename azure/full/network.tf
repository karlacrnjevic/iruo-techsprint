resource "azurerm_virtual_network" "techsprint" {
  name                = "vnet-techsprint"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name
}

resource "azurerm_subnet" "developer" {
  for_each = local.developer_subnets

  name                 = "snet-${each.key}"
  resource_group_name  = azurerm_resource_group.techsprint.name
  virtual_network_name = azurerm_virtual_network.techsprint.name
  address_prefixes     = [each.value]
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.techsprint.name
  virtual_network_name = azurerm_virtual_network.techsprint.name
  address_prefixes     = [local.management_subnet]
}
