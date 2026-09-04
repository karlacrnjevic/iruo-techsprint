variable "region" {
  description = "OpenStack region"
  type        = string
  default     = "regionOne"
}

variable "external_network_name" {
  description = "External OpenStack network used for router gateway and floating IPs"
  type        = string
  default     = "provider-datacentre"
}

variable "image_name" {
  description = "Image used for TechSprint virtual machines"
  type        = string
  default     = "rhel8"
}

variable "flavor_name" {
  description = "Flavor used for TechSprint virtual machines"
  type        = string
  default     = "default"
}

variable "users_csv_path" {
  description = "Path to the CSV file containing TechSprint users"
  type        = string
  default     = "../data/users.csv"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for TechSprint instances"
  type        = string
  default     = "~/.ssh/techsprint.pub"
}