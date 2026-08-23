terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Ovaj fajl Terraformu govori koja minimalna Terraform verzija smije izvršavati projekt i koji provider projekt treba

# azurerm je provider preko kojeg Terraform komunicira s Azureom:

# Terraform CLI
#    |
# azurerm provider
#    |
# Azure API
#    |
# Azure resursi