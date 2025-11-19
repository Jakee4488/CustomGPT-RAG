output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Login server for Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username for ACR"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "app_service_url" {
  description = "URL of the deployed application"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.app.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.enable_application_insights ? azurerm_application_insights.app_insights[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.enable_application_insights ? azurerm_application_insights.app_insights[0].connection_string : null
  sensitive   = true
}
