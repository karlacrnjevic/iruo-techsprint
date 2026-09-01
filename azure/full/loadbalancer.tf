resource "azurerm_lb" "techsprint" {
  name                = "lb-techsprint-internal"
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name
  sku                 = "Standard"

  tags = local.common_tags

  frontend_ip_configuration {
    name                          = "internal-frontend"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "moodle" {
  name            = "moodle-backend-pool"
  loadbalancer_id = azurerm_lb.techsprint.id
}

resource "azurerm_network_interface_backend_address_pool_association" "developer" {
  for_each = local.developers

  network_interface_id    = azurerm_network_interface.developer[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.moodle.id
}

resource "azurerm_lb_probe" "http" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.techsprint.id
  protocol            = "Http"
  port                = 80
  request_path        = "/moodle-health.html"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.techsprint.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "internal-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.moodle.id]
  probe_id                       = azurerm_lb_probe.http.id
}
