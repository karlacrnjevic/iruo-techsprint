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

  developer_usernames = sort(keys(local.developers))

  developer_networks = {
    for index, username in local.developer_usernames :
    username => cidrsubnet("10.10.0.0/16", 8, index + 1)
  }
}