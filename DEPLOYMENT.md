# Azure Deployment Guide - CustomGPT-RAG

This guide walks you through deploying the CustomGPT-RAG application to Azure using Docker containers, Terraform for infrastructure as code, and GitHub Actions for CI/CD.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Initial Setup](#initial-setup)
- [Local Development](#local-development)
- [Azure Infrastructure Setup](#azure-infrastructure-setup)
- [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
- [Deployment](#deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

Before you begin, ensure you have:

### Required Tools
- **Azure CLI** (v2.50+): [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform** (v1.6+): [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **Docker** (v24+): [Install Guide](https://docs.docker.com/get-docker/)
- **Git**: [Install Guide](https://git-scm.com/downloads)
- **Python** (3.10+): [Install Guide](https://www.python.org/downloads/)

### Azure Requirements
- Active Azure Subscription
- Contributor or Owner role on the subscription
- Resource quota for:
  - App Service Plan (P1v3 or higher recommended)
  - Container Registry
  - Storage Account

### GitHub Requirements
- GitHub account with repository access
- Ability to add secrets and configure workflows

---

## 🏗️ Architecture Overview

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Test & Lint │→ │ Build Docker │→ │ Deploy Azure │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Azure Resources                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Azure Container Registry (ACR)                      │  │
│  │  • Stores Docker images                              │  │
│  │  • Geo-replication (optional)                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  App Service (Linux Containers)                      │  │
│  │  • Runs Docker container                             │  │
│  │  • Auto-scaling capability                           │  │
│  │  • Health monitoring                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Azure Storage Account                               │  │
│  │  • SOURCE_DOCUMENTS (Blob)                           │  │
│  │  • DB (ChromaDB persistence)                         │  │
│  │  • models (Model cache)                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Insights (Optional)                     │  │
│  │  • Performance monitoring                            │  │
│  │  • Log aggregation                                   │  │
│  │  • Alerts and diagnostics                            │  │
│  └──────────────────────────────────────────────────────┘  │
│                              ↓                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Azure Key Vault                                     │  │
│  │  • Secrets management                                │  │
│  │  • ACR credentials                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Application Architecture

- **API Server** (Port 5110): Flask-based REST API for LLM interactions
- **UI Server** (Port 5111): Web interface for document upload and chat
- **Model Layer**: HuggingFace Transformers with optional GPU support
- **Vector Store**: ChromaDB for document embeddings
- **Document Processing**: Multi-format support (PDF, DOCX, TXT, CSV, XLSX)

---

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Jakee4488/CustomGPT-RAG.git
cd CustomGPT-RAG
```

### 2. Azure CLI Login

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Verify the subscription
az account show
```

### 3. Create Azure Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "customgpt-rag-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth

# Save the JSON output - you'll need it for GitHub secrets
```

The output will look like:
```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "...",
  ...
}
```

### 4. Create Terraform Backend Storage

Terraform needs a backend to store state files:

```bash
# Variables
RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY

echo "Terraform Backend Configuration:"
echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "resource_group_name: $RESOURCE_GROUP_NAME"
```

### 5. Configure Terraform Backend

Update `terraform/main.tf` with your backend configuration:

```bash
cd terraform

# Create backend configuration file
cat > backend.conf << EOF
resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "customgpt-rag.terraform.tfstate"
EOF

# Initialize Terraform with backend
terraform init -backend-config=backend.conf
```

---

## 💻 Local Development

### Docker Compose Setup

1. **Copy environment file:**
```bash
cp .env.example .env
```

2. **Edit `.env` file** with your preferences:
```env
DEVICE_TYPE=cpu
MODEL_ID=NousResearch/Llama-2-7b-chat-hf
EMBEDDING_MODEL_NAME=hkunlp/instructor-large
```

3. **Add sample documents** to `SOURCE_DOCUMENTS/` folder

4. **Build and run:**
```bash
# Build the Docker image
docker-compose build

# Start the services
docker-compose up -d

# View logs
docker-compose logs -f

# Access the application
# API: http://localhost:5110
# UI: http://localhost:5111
```

5. **Test the application:**
```bash
# Health check
curl http://localhost:5110/health

# Test with a prompt
curl -X POST http://localhost:5110/api/prompt_route \
  -F "user_prompt=What is this document about?"
```

### Manual Docker Build

```bash
# Build
docker build -t customgpt-rag:local .

# Run
docker run -d \
  --name customgpt-rag \
  -p 5110:5110 \
  -p 5111:5111 \
  -v $(pwd)/SOURCE_DOCUMENTS:/app/SOURCE_DOCUMENTS \
  -v $(pwd)/DB:/app/DB \
  -v $(pwd)/models:/app/models \
  -e DEVICE_TYPE=cpu \
  customgpt-rag:local

# View logs
docker logs -f customgpt-rag
```

---

## ☁️ Azure Infrastructure Setup

### Manual Terraform Deployment

1. **Navigate to terraform directory:**
```bash
cd terraform
```

2. **Initialize Terraform:**
```bash
terraform init -backend-config=backend.conf
```

3. **Plan the deployment:**
```bash
# For development environment
terraform plan -var-file="terraform.dev.tfvars" -out=tfplan

# For production environment
terraform plan -var-file="terraform.prod.tfvars" -out=tfplan
```

4. **Review the plan** and apply:
```bash
terraform apply tfplan
```

5. **Save the outputs:**
```bash
terraform output -json > outputs.json

# View specific outputs
terraform output app_service_url
terraform output acr_login_server
```

### Infrastructure Resources Created

- **Resource Group**: Container for all resources
- **Container Registry**: Stores Docker images
- **App Service Plan**: Compute resources (P1v3)
- **App Service**: Hosts the containerized application
- **Storage Account**: Persistent storage for documents, DB, models
- **Key Vault**: Secure secret storage
- **Application Insights**: (Optional) Monitoring and telemetry

### Cost Estimation

**Development Environment (terraform.dev.tfvars):**
- App Service Plan (B2): ~$60/month
- Container Registry (Basic): ~$5/month
- Storage Account: ~$5/month
- **Total: ~$70/month**

**Production Environment (terraform.prod.tfvars):**
- App Service Plan (P1v3): ~$145/month
- Container Registry (Standard): ~$20/month
- Storage Account: ~$10/month
- Application Insights: ~$10/month
- **Total: ~$185/month**

---

## 🔄 CI/CD Pipeline Configuration

### GitHub Secrets Setup

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

#### Required Secrets

1. **AZURE_CREDENTIALS**
   - The complete JSON output from service principal creation
   ```json
   {
     "clientId": "...",
     "clientSecret": "...",
     "subscriptionId": "...",
     "tenantId": "..."
   }
   ```

2. **ACR_LOGIN_SERVER**
   - Format: `<registry-name>.azurecr.io`
   - Get it: `terraform output acr_login_server`

3. **ACR_USERNAME**
   - Get it: `terraform output acr_admin_username`

4. **ACR_PASSWORD**
   - Get it: `terraform output acr_admin_password`

5. **AZURE_RESOURCE_GROUP**
   - Your Azure resource group name
   - Get it: `terraform output resource_group_name`

#### Optional Secrets

6. **HUGGINGFACE_TOKEN** (if using gated models)
   - Your HuggingFace access token

### GitHub Environments

Set up environments for deployment approvals:

1. Go to: Settings → Environments
2. Create two environments:
   - `development`
   - `production`

3. For `production`, configure:
   - **Required reviewers**: Add team members
   - **Wait timer**: 5 minutes (optional)
   - **Deployment branches**: Only `main`

### Workflow Files

The CI/CD pipeline consists of three workflows:

#### 1. **ci-cd.yml** - Main CI/CD Pipeline
- Triggers: Push to `main`/`develop`, manual dispatch
- Jobs:
  1. Run tests and linting
  2. Build and push Docker image to ACR
  3. Plan Terraform changes
  4. Apply infrastructure changes
  5. Deploy to Azure App Service
  6. Health check verification
  7. Send notifications

#### 2. **docker-test.yml** - Docker Build Testing
- Triggers: Pull requests
- Purpose: Validate Docker builds work correctly

#### 3. **terraform-destroy.yml** - Infrastructure Teardown
- Triggers: Manual only
- Purpose: Safely destroy infrastructure when needed

---

## 🚀 Deployment

### Automated Deployment (Recommended)

#### Deploy to Development

```bash
# Push to develop branch
git checkout develop
git add .
git commit -m "Deploy to development"
git push origin develop
```

#### Deploy to Production

```bash
# Push to main branch
git checkout main
git merge develop
git push origin main

# Requires approval in GitHub Actions UI
```

#### Manual Deployment Trigger

Use GitHub Actions UI:
1. Go to Actions tab
2. Select "CI/CD Pipeline"
3. Click "Run workflow"
4. Select branch and environment
5. Click "Run workflow"

### Manual Deployment

If you need to deploy without GitHub Actions:

```bash
# 1. Build Docker image locally
docker build -t customgpt-rag:latest .

# 2. Login to ACR
az acr login --name <your-acr-name>

# 3. Tag image
docker tag customgpt-rag:latest <acr-login-server>/customgpt-rag:latest

# 4. Push to ACR
docker push <acr-login-server>/customgpt-rag:latest

# 5. Restart App Service
az webapp restart \
  --name <app-service-name> \
  --resource-group <resource-group-name>
```

---

## 📊 Monitoring and Maintenance

### Application Insights

If enabled, view metrics:
```bash
# Get instrumentation key
terraform output application_insights_instrumentation_key

# View in Azure Portal
az portal open \
  --resource-group <resource-group-name>
```

### View Logs

**Azure Portal:**
```
App Service → Monitoring → Log stream
```

**Azure CLI:**
```bash
# Stream logs
az webapp log tail \
  --name <app-service-name> \
  --resource-group <resource-group-name>

# Download logs
az webapp log download \
  --name <app-service-name> \
  --resource-group <resource-group-name> \
  --log-file logs.zip
```

### Health Checks

```bash
# Check application health
curl https://<app-service-name>.azurewebsites.net/health

# Expected response
{"status":"healthy","device":"cpu"}
```

### Scale App Service

**Manual scaling:**
```bash
az appservice plan update \
  --name <plan-name> \
  --resource-group <resource-group-name> \
  --sku P2v3
```

**Auto-scaling:**
```bash
# Enable autoscale
az monitor autoscale create \
  --resource-group <resource-group-name> \
  --resource <app-service-plan-id> \
  --min-count 1 \
  --max-count 5 \
  --count 1
```

### Backup and Disaster Recovery

**Backup Storage Account:**
```bash
# Enable soft delete
az storage account blob-service-properties update \
  --account-name <storage-account-name> \
  --enable-delete-retention true \
  --delete-retention-days 30
```

**Backup Database:**
```bash
# Sync DB to local
az storage blob download-batch \
  --account-name <storage-account-name> \
  --source database \
  --destination ./backup/DB
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Container Fails to Start

**Symptoms:** App Service shows unhealthy or container keeps restarting

**Solutions:**
```bash
# Check container logs
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>

# Verify environment variables
az webapp config appsettings list --name <app-service-name> --resource-group <resource-group-name>

# Check ACR credentials
az acr credential show --name <acr-name>
```

#### 2. Health Check Failing

**Symptoms:** `/health` endpoint returns 503 or timeout

**Solutions:**
```bash
# SSH into container
az webapp ssh --name <app-service-name> --resource-group <resource-group-name>

# Inside container, check processes
ps aux | grep python

# Check if API is listening
netstat -tlnp | grep 5110

# Test health endpoint internally
curl localhost:5110/health
```

#### 3. Out of Memory Errors

**Symptoms:** Container crashes, OOM errors in logs

**Solutions:**
- Upgrade App Service Plan to higher tier
- Optimize model selection (use smaller models)
- Enable swap file in container
- Use CPU-only mode instead of attempting GPU

```bash
# Scale up App Service Plan
az appservice plan update \
  --name <plan-name> \
  --resource-group <resource-group-name> \
  --sku P2v3
```

#### 4. Terraform State Lock

**Symptoms:** "Error acquiring the state lock"

**Solutions:**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Or delete lock from storage
az storage blob delete \
  --account-name <storage-account-name> \
  --container-name tfstate \
  --name customgpt-rag.terraform.tfstate.lock
```

#### 5. GitHub Actions Pipeline Fails

**Build Stage:**
- Check Docker syntax in Dockerfile
- Verify all requirements.txt dependencies are available
- Check ACR credentials in secrets

**Terraform Stage:**
- Verify Azure credentials are valid
- Check quota limits in Azure subscription
- Ensure backend storage account exists

**Deploy Stage:**
- Verify App Service has pulled latest image
- Check health endpoint is responding
- Review application logs

### Debug Commands

```bash
# Check Azure resource status
az resource list --resource-group <resource-group-name> --output table

# Verify ACR image tags
az acr repository show-tags --name <acr-name> --repository customgpt-rag

# Test Docker image locally
docker run -it --rm <acr-login-server>/customgpt-rag:latest /bin/bash

# Check Terraform state
terraform state list
terraform state show <resource-name>

# Verify network connectivity
az network vnet list --resource-group <resource-group-name>
```

---

## 📚 Additional Resources

### Documentation
- [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

### Community
- [GitHub Issues](https://github.com/Jakee4488/CustomGPT-RAG/issues)
- [Discussions](https://github.com/Jakee4488/CustomGPT-RAG/discussions)

### Cost Optimization
- Use development environment for testing
- Schedule App Service to stop during non-business hours
- Use spot instances for non-critical workloads
- Enable autoscaling with appropriate metrics

### Security Best Practices
- Rotate ACR credentials regularly
- Use managed identities instead of credentials where possible
- Enable Azure Key Vault soft delete and purge protection
- Implement network security groups
- Enable Azure Defender for containers

---

## 🔐 Security Considerations

1. **Secrets Management**
   - Never commit secrets to Git
   - Use Azure Key Vault for production secrets
   - Rotate credentials regularly

2. **Network Security**
   - Consider using Azure Private Link for ACR
   - Implement IP restrictions on App Service
   - Use Azure Front Door for DDoS protection

3. **Container Security**
   - Regularly update base images
   - Scan images for vulnerabilities
   - Use minimal base images

4. **Access Control**
   - Implement Azure RBAC
   - Use managed identities
   - Follow principle of least privilege

---

## 📝 License

This deployment guide is part of the CustomGPT-RAG project. See LICENSE file for details.

---

## 🤝 Contributing

Contributions to improve this deployment solution are welcome! Please submit pull requests or open issues.

---

**Last Updated:** November 2025  
**Version:** 1.0.0
