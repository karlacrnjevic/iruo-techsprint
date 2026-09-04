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

    management_network = "10.10.100.0/24"

      moodle_instances = merge([
    for username, user in local.developers : {
      for instance_number in range(1, 3) :
      "${username}-${instance_number}" => {
        username        = username
        instance_number = instance_number
      }
    }
  ]...)
}