terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend configuration for state storage
  backend "azurerm" {
    # These values should be provided via backend config file or CLI
    # resource_group_name  = "tfstate-rg"
    # storage_account_name = "tfstate<unique>"
    # container_name       = "tfstate"
    # key                  = "customgpt-rag.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
