# Keystone IAM resources.
# Disabled by default because the Red Hat Academy developer account
# does not have administrative Keystone permissions.
#
# In an OpenStack environment with Keystone admin privileges:
# terraform apply -var="enable_iam=true"

resource "openstack_identity_project_v3" "developer" {
  for_each = var.enable_iam ? local.developers : {}

  name        = "techsprint-${each.key}"
  description = "TechSprint isolated project for developer ${each.key}"
  enabled     = true
}

resource "openstack_identity_project_v3" "management" {
  count = var.enable_iam ? 1 : 0

  name        = "techsprint-management"
  description = "TechSprint management project for DevOps lead"
  enabled     = true
}

resource "openstack_identity_group_v3" "developers" {
  count = var.enable_iam ? 1 : 0

  name        = "techsprint-developers"
  description = "TechSprint developer users"
}

resource "openstack_identity_group_v3" "leads" {
  count = var.enable_iam ? 1 : 0

  name        = "techsprint-devops-leads"
  description = "TechSprint DevOps lead users"
}

resource "openstack_identity_role_v3" "developer" {
  count = var.enable_iam ? 1 : 0

  name = "techsprint-developer"
}

resource "openstack_identity_role_v3" "lead" {
  count = var.enable_iam ? 1 : 0

  name = "techsprint-devops-lead"
}

resource "openstack_identity_user_v3" "developer" {
  for_each = var.enable_iam ? local.developers : {}

  name               = each.key
  description        = "TechSprint developer ${each.key}"
  default_project_id = openstack_identity_project_v3.developer[each.key].id
  enabled            = true
}

resource "openstack_identity_user_v3" "lead" {
  for_each = var.enable_iam ? local.leads : {}

  name               = each.key
  description        = "TechSprint DevOps lead ${each.key}"
  default_project_id = openstack_identity_project_v3.management[0].id
  enabled            = true
}

resource "openstack_identity_user_membership_v3" "developer" {
  for_each = var.enable_iam ? local.developers : {}

  user_id  = openstack_identity_user_v3.developer[each.key].id
  group_id = openstack_identity_group_v3.developers[0].id
}

resource "openstack_identity_user_membership_v3" "lead" {
  for_each = var.enable_iam ? local.leads : {}

  user_id  = openstack_identity_user_v3.lead[each.key].id
  group_id = openstack_identity_group_v3.leads[0].id
}

# Developers receive the developer role only in their own project.
resource "openstack_identity_role_assignment_v3" "developer_own_project" {
  for_each = var.enable_iam ? local.developers : {}

  group_id   = openstack_identity_group_v3.developers[0].id
  project_id = openstack_identity_project_v3.developer[each.key].id
  role_id    = openstack_identity_role_v3.developer[0].id
}

# Lead receives lead role in the management project.
resource "openstack_identity_role_assignment_v3" "lead_management" {
  count = var.enable_iam ? 1 : 0

  group_id   = openstack_identity_group_v3.leads[0].id
  project_id = openstack_identity_project_v3.management[0].id
  role_id    = openstack_identity_role_v3.lead[0].id
}

# Lead receives lead role in every developer project.
resource "openstack_identity_role_assignment_v3" "lead_developer_projects" {
  for_each = var.enable_iam ? local.developers : {}

  group_id   = openstack_identity_group_v3.leads[0].id
  project_id = openstack_identity_project_v3.developer[each.key].id
  role_id    = openstack_identity_role_v3.lead[0].id
}
