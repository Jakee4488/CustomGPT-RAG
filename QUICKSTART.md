# Quick Start Guide - Azure Deployment

This is a condensed version of the full deployment guide. For comprehensive documentation, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites Checklist

- [ ] Azure subscription with Contributor role
- [ ] Azure CLI installed and logged in
- [ ] Terraform v1.6+ installed
- [ ] Docker installed
- [ ] GitHub account with repo access

## 5-Minute Setup

### 1. Azure Service Principal

```bash
# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Create service principal
az ad sp create-for-rbac \
  --name "customgpt-rag-github" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth > azure-credentials.json
```

### 2. Terraform Backend

```bash
# Create storage for Terraform state
STORAGE_NAME="tfstate$(openssl rand -hex 4)"

az group create --name tfstate-rg --location eastus

az storage account create \
  --name $STORAGE_NAME \
  --resource-group tfstate-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME \
  --auth-mode login
```

### 3. Initial Terraform Deployment

```bash
cd terraform

# Create backend config
cat > backend.conf << EOF
resource_group_name  = "tfstate-rg"
storage_account_name = "$STORAGE_NAME"
container_name       = "tfstate"
key                  = "customgpt-rag.terraform.tfstate"
EOF

# Deploy infrastructure
terraform init -backend-config=backend.conf
terraform plan -var-file="terraform.dev.tfvars" -out=tfplan
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

### 4. Configure GitHub Secrets

Go to: Repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value | How to Get |
|------------|-------|------------|
| `AZURE_CREDENTIALS` | JSON from step 1 | `cat azure-credentials.json` |
| `ACR_LOGIN_SERVER` | ACR URL | `terraform output acr_login_server` |
| `ACR_USERNAME` | ACR admin user | `terraform output acr_admin_username` |
| `ACR_PASSWORD` | ACR admin password | `terraform output acr_admin_password` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `terraform output resource_group_name` |

### 5. Deploy Application

```bash
# Push to trigger deployment
git add .
git commit -m "Initial deployment"
git push origin main
```

Monitor deployment: Repository → Actions tab

### 6. Verify Deployment

```bash
# Get app URL
APP_URL=$(terraform output -raw app_service_url)

# Check health
curl $APP_URL/health

# Open in browser
echo "Application URL: $APP_URL"
```

## Local Testing

```bash
# Copy environment file
cp .env.example .env

# Add sample documents to SOURCE_DOCUMENTS/

# Run with Docker Compose
docker-compose up -d

# Access locally
# API: http://localhost:5110
# UI: http://localhost:5111
```

## Common Commands

```bash
# View logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Restart app
az webapp restart --name <app-name> --resource-group <rg-name>

# Scale up
az appservice plan update --name <plan-name> --resource-group <rg-name> --sku P2v3

# Destroy infrastructure
cd terraform
terraform destroy -var-file="terraform.dev.tfvars"
```

## Troubleshooting

**Container won't start:**
```bash
az webapp log tail --name <app-name> --resource-group <rg-name>
```

**Health check failing:**
```bash
az webapp ssh --name <app-name> --resource-group <rg-name>
curl localhost:5110/health
```

**GitHub Actions failing:**
- Verify all secrets are set correctly
- Check Azure credentials haven't expired
- Ensure resource quotas aren't exceeded

## Architecture

```
GitHub Actions → Docker Build → Azure Container Registry
                                         ↓
                              Azure App Service (Linux)
                                         ↓
                    Azure Storage (Documents, DB, Models)
```

## Cost Estimate

- **Development**: ~$70/month
- **Production**: ~$185/month

## Next Steps

1. Add your documents to `SOURCE_DOCUMENTS/`
2. Configure custom models in `constants.py`
3. Set up monitoring in Azure Portal
4. Review security settings
5. Configure autoscaling

## Full Documentation

For detailed information, see:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [README.md](README.md) - Application documentation
- [terraform/](terraform/) - Infrastructure code

## Support

- Issues: https://github.com/Jakee4488/CustomGPT-RAG/issues
- Discussions: https://github.com/Jakee4488/CustomGPT-RAG/discussions

---

**Need help?** Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.
