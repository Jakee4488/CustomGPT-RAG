# Development environment configuration
environment             = "dev"
location                = "eastus"
acr_sku                 = "Basic"
app_service_plan_sku    = "B2"
enable_application_insights = false
device_type             = "cpu"

tags = {
  Project     = "CustomGPT-RAG"
  Environment = "Development"
  ManagedBy   = "Terraform"
}
