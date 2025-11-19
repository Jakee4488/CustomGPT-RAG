# Deployment Scripts

This directory contains automation scripts for deploying CustomGPT-RAG to Azure.

## Scripts

### setup-azure.sh
Initial Azure setup including service principal, Terraform backend, and configuration.

**Usage:**
```bash
./scripts/setup-azure.sh
```

**What it does:**
- Creates Azure service principal for GitHub Actions
- Sets up Terraform backend storage account
- Initializes Terraform configuration
- Generates configuration files

**Output:**
- `azure-credentials.json` - Service principal credentials (keep secure!)
- `terraform/backend.conf` - Terraform backend configuration

### deploy.sh
Deploys application to Azure including infrastructure provisioning.

**Usage:**
```bash
# Deploy to development
./scripts/deploy.sh --env dev

# Deploy to production
./scripts/deploy.sh --env prod

# Auto-approve (skip confirmations)
./scripts/deploy.sh --env prod --auto-approve
```

**What it does:**
- Builds Docker image
- Initializes and validates Terraform
- Plans and applies infrastructure changes
- Pushes image to Azure Container Registry
- Restarts App Service
- Verifies deployment health

### cleanup.sh
Destroys Azure infrastructure for specified environment.

**Usage:**
```bash
# Destroy development environment
./scripts/cleanup.sh --env dev

# Destroy production environment
./scripts/cleanup.sh --env prod
```

**What it does:**
- Confirms destruction (requires typing 'destroy')
- Runs terraform destroy
- Removes all Azure resources

## Prerequisites

All scripts require:
- Azure CLI (`az`) - [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Terraform (`terraform`) - [Install](https://developer.hashicorp.com/terraform/downloads)
- Docker (`docker`) - [Install](https://docs.docker.com/get-docker/)
- Bash shell

## Workflow

1. **Initial Setup:**
   ```bash
   ./scripts/setup-azure.sh
   ```

2. **Configure GitHub Secrets** with outputs from step 1

3. **Deploy to Development:**
   ```bash
   ./scripts/deploy.sh --env dev
   ```

4. **Test and Verify**

5. **Deploy to Production:**
   ```bash
   ./scripts/deploy.sh --env prod
   ```

6. **Cleanup** (when needed):
   ```bash
   ./scripts/cleanup.sh --env dev
   ```

## Making Scripts Executable

On Linux/Mac:
```bash
chmod +x scripts/*.sh
```

On Windows (Git Bash):
```bash
git update-index --chmod=+x scripts/*.sh
```

## Troubleshooting

**Permission Denied:**
```bash
chmod +x scripts/<script-name>.sh
```

**Azure Login Failed:**
```bash
az login
az account set --subscription "<your-subscription-id>"
```

**Terraform Backend Error:**
- Ensure `terraform/backend.conf` exists
- Run `./scripts/setup-azure.sh` first

**Docker Build Failed:**
- Check Docker daemon is running
- Verify Dockerfile syntax
- Check disk space

## Security Notes

⚠️ **Important:**
- Never commit `azure-credentials.json` to Git
- Store credentials securely (e.g., password manager)
- Rotate service principal credentials regularly
- Use Azure Key Vault for production secrets

## Support

For issues or questions:
- Check [DEPLOYMENT.md](../DEPLOYMENT.md) for detailed documentation
- Open an issue on GitHub
- Review logs: `az webapp log tail --name <app-name> --resource-group <rg-name>`
