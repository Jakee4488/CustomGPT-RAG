#!/bin/bash

# Deployment Script for CustomGPT-RAG
# Automates the deployment process to Azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ENVIRONMENT="dev"
AUTO_APPROVE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    --help)
      echo "Usage: ./deploy.sh [options]"
      echo ""
      echo "Options:"
      echo "  --env <environment>    Deployment environment (dev|prod) [default: dev]"
      echo "  --auto-approve         Skip confirmation prompts"
      echo "  --help                 Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}CustomGPT-RAG Deployment${NC}"
echo -e "${BLUE}Environment: $ENVIRONMENT${NC}"
echo -e "${BLUE}==================================${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI required${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform required${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker required${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ Prerequisites OK${NC}\n"

# Login to Azure
echo -e "${YELLOW}Checking Azure authentication...${NC}"
az account show >/dev/null 2>&1 || az login
echo -e "${GREEN}✓ Azure authenticated${NC}\n"

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t customgpt-rag:$ENVIRONMENT .
echo -e "${GREEN}✓ Docker image built${NC}\n"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
if [ -f backend.conf ]; then
  terraform init -backend-config=backend.conf -upgrade
else
  echo -e "${RED}Error: backend.conf not found${NC}"
  echo "Run ./scripts/setup-azure.sh first"
  exit 1
fi
echo -e "${GREEN}✓ Terraform initialized${NC}\n"

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate
echo -e "${GREEN}✓ Configuration valid${NC}\n"

# Plan infrastructure changes
echo -e "${YELLOW}Planning infrastructure changes...${NC}"
terraform plan -var-file="terraform.$ENVIRONMENT.tfvars" -out=tfplan
echo -e "${GREEN}✓ Plan created${NC}\n"

# Confirm deployment
if [ "$AUTO_APPROVE" = false ]; then
  echo -e "${YELLOW}Review the plan above.${NC}"
  read -p "Do you want to apply these changes? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 0
  fi
fi

# Apply infrastructure changes
echo -e "${YELLOW}Applying infrastructure changes...${NC}"
terraform apply tfplan
echo -e "${GREEN}✓ Infrastructure deployed${NC}\n"

# Get outputs
echo -e "${YELLOW}Retrieving deployment information...${NC}"
terraform output -json > outputs.json

ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(terraform output -raw acr_admin_password)
APP_SERVICE_NAME=$(terraform output -raw app_service_name)
APP_SERVICE_URL=$(terraform output -raw app_service_url)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

echo -e "${GREEN}✓ Outputs retrieved${NC}\n"

# Login to ACR
echo -e "${YELLOW}Logging into Azure Container Registry...${NC}"
echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin
echo -e "${GREEN}✓ ACR login successful${NC}\n"

# Tag and push Docker image
echo -e "${YELLOW}Pushing Docker image to ACR...${NC}"
docker tag customgpt-rag:$ENVIRONMENT "$ACR_LOGIN_SERVER/customgpt-rag:$ENVIRONMENT"
docker tag customgpt-rag:$ENVIRONMENT "$ACR_LOGIN_SERVER/customgpt-rag:latest"
docker push "$ACR_LOGIN_SERVER/customgpt-rag:$ENVIRONMENT"
docker push "$ACR_LOGIN_SERVER/customgpt-rag:latest"
echo -e "${GREEN}✓ Image pushed to ACR${NC}\n"

# Restart App Service
echo -e "${YELLOW}Restarting App Service...${NC}"
az webapp restart --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP"
echo -e "${GREEN}✓ App Service restarted${NC}\n"

# Wait for application to be ready
echo -e "${YELLOW}Waiting for application to be ready...${NC}"
for i in {1..30}; do
  if curl -sf "$APP_SERVICE_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Application is healthy${NC}\n"
    break
  fi
  echo "  Attempt $i/30..."
  sleep 10
done

# Deployment summary
cd ..

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}==================================${NC}\n"

echo -e "${BLUE}Application URL:${NC} $APP_SERVICE_URL"
echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}Resource Group:${NC} $RESOURCE_GROUP"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs:    az webapp log tail --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "  SSH to app:   az webapp ssh --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo "  Restart app:  az webapp restart --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo -e "${GREEN}Access your application at: $APP_SERVICE_URL${NC}"
