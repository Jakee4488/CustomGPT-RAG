#!/bin/bash

# Azure Setup Script for CustomGPT-RAG
# This script automates the initial Azure setup including:
# - Service principal creation
# - Terraform backend storage
# - GitHub secrets configuration helper

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}CustomGPT-RAG Azure Setup${NC}"
echo -e "${GREEN}==================================${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI is required but not installed.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ Prerequisites OK${NC}\n"

# Azure Login
echo -e "${YELLOW}Logging into Azure...${NC}"
az login

# Get subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Using subscription: $SUBSCRIPTION_ID${NC}\n"

# Project configuration
PROJECT_NAME="customgpt-rag"
LOCATION="eastus"
RANDOM_SUFFIX=$(openssl rand -hex 3)

# Create Service Principal
echo -e "${YELLOW}Creating service principal...${NC}"
SP_NAME="${PROJECT_NAME}-github-actions-${RANDOM_SUFFIX}"

SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role Contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth)

echo "$SP_OUTPUT" > azure-credentials.json
echo -e "${GREEN}✓ Service principal created: $SP_NAME${NC}"
echo -e "${GREEN}✓ Credentials saved to: azure-credentials.json${NC}\n"

# Create Terraform Backend Storage
echo -e "${YELLOW}Creating Terraform backend storage...${NC}"

TFSTATE_RG="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate${RANDOM_SUFFIX}"

# Create resource group
az group create \
  --name "$TFSTATE_RG" \
  --location "$LOCATION" \
  --output none

echo -e "${GREEN}✓ Resource group created: $TFSTATE_RG${NC}"

# Create storage account
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$TFSTATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --output none

echo -e "${GREEN}✓ Storage account created: $STORAGE_ACCOUNT_NAME${NC}"

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group "$TFSTATE_RG" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --query '[0].value' -o tsv)

# Create blob container
az storage container create \
  --name tfstate \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --output none

echo -e "${GREEN}✓ Storage container created: tfstate${NC}\n"

# Create backend configuration
echo -e "${YELLOW}Creating Terraform backend configuration...${NC}"

cd terraform

cat > backend.conf << EOF
resource_group_name  = "$TFSTATE_RG"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "tfstate"
key                  = "customgpt-rag.terraform.tfstate"
EOF

echo -e "${GREEN}✓ Backend configuration saved to: terraform/backend.conf${NC}\n"

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init -backend-config=backend.conf

echo -e "${GREEN}✓ Terraform initialized${NC}\n"

cd ..

# Summary
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}\n"

echo "1. Configure GitHub Secrets:"
echo "   Go to: Repository → Settings → Secrets and variables → Actions"
echo ""
echo "   Add the following secrets:"
echo "   - AZURE_CREDENTIALS (content of azure-credentials.json)"
echo "   - AZURE_RESOURCE_GROUP (you'll get this after terraform apply)"
echo "   - ACR_LOGIN_SERVER (you'll get this after terraform apply)"
echo "   - ACR_USERNAME (you'll get this after terraform apply)"
echo "   - ACR_PASSWORD (you'll get this after terraform apply)"
echo ""

echo "2. Deploy infrastructure:"
echo "   cd terraform"
echo "   terraform plan -var-file=terraform.dev.tfvars -out=tfplan"
echo "   terraform apply tfplan"
echo ""

echo "3. Get Azure outputs for GitHub secrets:"
echo "   terraform output -json > outputs.json"
echo "   terraform output acr_login_server"
echo "   terraform output acr_admin_username"
echo "   terraform output acr_admin_password"
echo "   terraform output resource_group_name"
echo ""

echo "4. Push to GitHub to trigger deployment:"
echo "   git add ."
echo "   git commit -m 'Initial deployment'"
echo "   git push origin main"
echo ""

echo -e "${GREEN}==================================${NC}"
echo -e "${YELLOW}Important Files Created:${NC}"
echo "- azure-credentials.json (keep secure, needed for GitHub)"
echo "- terraform/backend.conf (Terraform backend config)"
echo ""
echo -e "${RED}⚠️  Keep azure-credentials.json secure and do not commit to git!${NC}"
