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

  developer_subnets = {
    for index, username in sort(keys(local.developers)) :
    username => cidrsubnet(var.vnet_address_space[0], 8, index + 10)
  }

  management_subnet = "10.10.100.0/24"
}
