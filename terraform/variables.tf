variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "customgpt-rag"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "P1v3"
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "enable_application_insights" {
  description = "Enable Application Insights monitoring"
  type        = bool
  default     = true
}

variable "model_id" {
  description = "HuggingFace model ID"
  type        = string
  default     = "NousResearch/Llama-2-7b-chat-hf"
}

variable "embedding_model_name" {
  description = "Embedding model name"
  type        = string
  default     = "hkunlp/instructor-large"
}

variable "device_type" {
  description = "Device type for model inference (cpu/cuda)"
  type        = string
  default     = "cpu"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CustomGPT-RAG"
    ManagedBy   = "Terraform"
  }
}
