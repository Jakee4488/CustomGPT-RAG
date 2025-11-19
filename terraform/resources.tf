# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = merge(var.tags, { Environment = var.environment })
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true

  tags = merge(var.tags, { Environment = var.environment })
}

# Storage Account for persistent data
resource "azurerm_storage_account" "storage" {
  name                     = "${replace(var.project_name, "-", "")}${var.environment}st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = merge(var.tags, { Environment = var.environment })
}

# Storage Container for documents
resource "azurerm_storage_container" "documents" {
  name                  = "source-documents"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Storage Container for database
resource "azurerm_storage_container" "database" {
  name                  = "database"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Storage Container for models
resource "azurerm_storage_container" "models" {
  name                  = "models"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# File Share for persistent storage
resource "azurerm_storage_share" "app_data" {
  name                 = "app-data"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 100
}

# App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = merge(var.tags, { Environment = var.environment })
}

# Linux Web App (Container)
resource "azurerm_linux_web_app" "app" {
  name                = "${var.project_name}-${var.environment}-app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    always_on = true
    
    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/${var.project_name}"
      docker_image_tag = var.docker_image_tag
    }

    health_check_path = "/health"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DEVICE_TYPE"                         = var.device_type
    "MODEL_ID"                            = var.model_id
    "EMBEDDING_MODEL_NAME"                = var.embedding_model_name
    "PERSIST_DIRECTORY"                   = "/app/DB"
    "SOURCE_DIRECTORY"                    = "/app/SOURCE_DOCUMENTS"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.enable_application_insights ? azurerm_application_insights.app_insights[0].connection_string : ""
  }

  storage_account {
    name         = "documents"
    type         = "AzureBlob"
    account_name = azurerm_storage_account.storage.name
    access_key   = azurerm_storage_account.storage.primary_access_key
    share_name   = azurerm_storage_container.documents.name
    mount_path   = "/app/SOURCE_DOCUMENTS"
  }

  storage_account {
    name         = "database"
    type         = "AzureBlob"
    account_name = azurerm_storage_account.storage.name
    access_key   = azurerm_storage_account.storage.primary_access_key
    share_name   = azurerm_storage_container.database.name
    mount_path   = "/app/DB"
  }

  storage_account {
    name         = "models"
    type         = "AzureBlob"
    account_name = azurerm_storage_account.storage.name
    access_key   = azurerm_storage_account.storage.primary_access_key
    share_name   = azurerm_storage_container.models.name
    mount_path   = "/app/models"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, { Environment = var.environment })
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  count               = var.enable_application_insights ? 1 : 0
  name                = "${var.project_name}-${var.environment}-insights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"

  tags = merge(var.tags, { Environment = var.environment })
}

# Key Vault for secrets management
resource "azurerm_key_vault" "kv" {
  name                       = "${var.project_name}-${var.environment}-kv-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.app.identity[0].principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }

  tags = merge(var.tags, { Environment = var.environment })
}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

# Data source for current Azure client config
data "azurerm_client_config" "current" {}
