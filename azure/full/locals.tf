locals {
  users = csvdecode(file(var.users_csv_path))

  developers = {
    for user in local.users :
    user.username => user
    if user.role == "developer"
  }

  leads = {
    for user in local.users :
    user.username => user
    if user.role == "lead"
  }

  developer_vnets = {
    for index, username in sort(keys(local.developers)) :
    username => cidrsubnet(var.vnet_address_space[0], 8, index + 1)
  }

  developer_subnets = {
    for username, cidr in local.developer_vnets :
    username => cidrsubnet(cidr, 4, 0)
  }

  management_vnet   = "10.10.100.0/24"
  management_subnet = "10.10.100.0/25"

  common_tags = {
    project     = "techsprint"
    environment = "testing"
  }
}