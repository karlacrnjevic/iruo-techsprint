variable "location" {
  description = "Azure region used for TechSprint resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the main TechSprint resource group"
  type        = string
  default     = "rg-techsprint"
}

variable "users_csv_path" {
  description = "Path to the CSV file containing TechSprint users"
  type        = string
  default     = "../../data/users.csv"
}

variable "vnet_address_space" {
  description = "Address space for the TechSprint virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "admin_username" {
  description = "Administrator username for Linux virtual machines"
  type        = string
  default     = "techadmin"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for virtual machines"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_size" {
  description = "Azure VM size used for developer environments"
  type        = string
  default     = "Standard_B2s"
}

variable "developer_principal_ids" {
  description = "Map of developer usernames to Microsoft Entra principal object IDs"
  type        = map(string)
  default     = {}
}

variable "lead_principal_id" {
  description = "Microsoft Entra principal object ID for the TechSprint lead"
  type        = string
  default     = ""
}

variable "moodle_db_password" {
  description = "Password for the local Moodle database user"
  type        = string
  sensitive   = true
}