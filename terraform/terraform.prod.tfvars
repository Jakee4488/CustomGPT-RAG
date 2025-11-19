# Production environment configuration
environment             = "prod"
location                = "eastus"
acr_sku                 = "Standard"
app_service_plan_sku    = "P1v3"
enable_application_insights = true
device_type             = "cpu"

tags = {
  Project     = "CustomGPT-RAG"
  Environment = "Production"
  ManagedBy   = "Terraform"
}
