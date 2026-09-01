resource "azurerm_network_interface" "developer" {
  for_each = local.developers

  name                = "nic-${each.key}"
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name

  tags = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.developer[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "developer" {
  for_each = local.developers

  name                = "vm-${each.key}-moodle"
  resource_group_name = azurerm_resource_group.techsprint.name
  location            = azurerm_resource_group.techsprint.location
  size                = var.vm_size
  admin_username      = var.admin_username

  tags = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(
    templatefile("${path.module}/scripts/moodle-bootstrap.sh", {
      moodle_db_password = var.moodle_db_password
    })
  )

  network_interface_ids = [
    azurerm_network_interface.developer[each.key].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "jump" {
  name                = "pip-jump"
  resource_group_name = azurerm_resource_group.techsprint.name
  location            = azurerm_resource_group.techsprint.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_network_interface" "jump" {
  name                = "nic-jump"
  location            = azurerm_resource_group.techsprint.location
  resource_group_name = azurerm_resource_group.techsprint.name

  tags = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump.id

  }
}

resource "azurerm_linux_virtual_machine" "jump" {
  name                = "vm-techsprint-jump"
  resource_group_name = azurerm_resource_group.techsprint.name
  location            = azurerm_resource_group.techsprint.location
  size                = var.vm_size
  admin_username      = var.admin_username

  tags = local.common_tags

  network_interface_ids = [
    azurerm_network_interface.jump.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))

  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
