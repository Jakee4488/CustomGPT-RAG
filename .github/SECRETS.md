# GitHub Secrets Configuration Guide

This guide helps you configure the required GitHub secrets for the CI/CD pipeline.

## Required Secrets

Navigate to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

### 1. AZURE_CREDENTIALS

**Description**: Azure service principal credentials for authentication

**How to get**:
```bash
# Run the setup script
./scripts/setup-azure.sh

# Or manually create service principal
az ad sp create-for-rbac \
  --name "customgpt-rag-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

**Value format** (entire JSON output):
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

---

### 2. ACR_LOGIN_SERVER

**Description**: Azure Container Registry login server URL

**How to get**:
```bash
# After running terraform apply
cd terraform
terraform output acr_login_server

# Or via Azure CLI
az acr show --name <acr-name> --query loginServer -o tsv
```

**Value format**: `<registry-name>.azurecr.io`

**Example**: `customgptragprodacr123456.azurecr.io`

---

### 3. ACR_USERNAME

**Description**: Azure Container Registry admin username

**How to get**:
```bash
# After running terraform apply
cd terraform
terraform output acr_admin_username

# Or via Azure CLI
az acr credential show --name <acr-name> --query username -o tsv
```

**Value format**: String (usually the ACR name)

**Example**: `customgptragprodacr123456`

---

### 4. ACR_PASSWORD

**Description**: Azure Container Registry admin password

**How to get**:
```bash
# After running terraform apply
cd terraform
terraform output acr_admin_password

# Or via Azure CLI
az acr credential show --name <acr-name> --query "passwords[0].value" -o tsv
```

**Value format**: Long alphanumeric string

**Example**: `Ab1Cd2Ef3Gh4Ij5Kl6Mn7Op8Qr9St0Uv1Wx2Yz3`

---

### 5. AZURE_RESOURCE_GROUP

**Description**: Name of the Azure resource group

**How to get**:
```bash
# After running terraform apply
cd terraform
terraform output resource_group_name

# Or list resource groups
az group list --query "[].name" -o table
```

**Value format**: String

**Example**: `customgpt-rag-prod-rg`

---

## Optional Secrets

### HUGGINGFACE_TOKEN

**Description**: HuggingFace API token for accessing gated models

**How to get**:
1. Go to https://huggingface.co/settings/tokens
2. Create a new token with read access
3. Copy the token value

**Value format**: `hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**When needed**: Only if using gated models that require authentication

---

## Verification Checklist

After adding all secrets, verify:

- [ ] All 5 required secrets are added
- [ ] Secret names match exactly (case-sensitive)
- [ ] No extra spaces in secret values
- [ ] AZURE_CREDENTIALS is valid JSON
- [ ] ACR credentials are from the correct registry
- [ ] Resource group name matches your deployment

---

## Quick Setup Script

Use this script to extract and display all values:

```bash
#!/bin/bash

echo "GitHub Secrets Configuration"
echo "============================"
echo ""

# Get Azure credentials
echo "1. AZURE_CREDENTIALS:"
echo "   (Use the JSON from: ./azure-credentials.json)"
echo ""

# Navigate to terraform directory
cd terraform

# Initialize if needed
if [ ! -d ".terraform" ]; then
    terraform init -backend-config=backend.conf
fi

echo "2. ACR_LOGIN_SERVER:"
terraform output -raw acr_login_server
echo ""
echo ""

echo "3. ACR_USERNAME:"
terraform output -raw acr_admin_username
echo ""
echo ""

echo "4. ACR_PASSWORD:"
terraform output -raw acr_admin_password
echo ""
echo ""

echo "5. AZURE_RESOURCE_GROUP:"
terraform output -raw resource_group_name
echo ""
echo ""

cd ..

echo "============================"
echo "Copy these values to GitHub Secrets"
echo "Navigate to: Repository → Settings → Secrets and variables → Actions"
```

Save as `scripts/get-secrets.sh` and run:
```bash
chmod +x scripts/get-secrets.sh
./scripts/get-secrets.sh
```

---

## Troubleshooting

### "Secret not found" error in GitHub Actions

**Problem**: Pipeline can't find a required secret

**Solution**:
1. Check secret name spelling (exact match required)
2. Verify secret is in the correct repository
3. Check if secret has a value (not empty)

### "Invalid Azure credentials" error

**Problem**: AZURE_CREDENTIALS is invalid or expired

**Solution**:
```bash
# Recreate service principal
az ad sp create-for-rbac \
  --name "customgpt-rag-github-actions-new" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Update the secret in GitHub
```

### "ACR authentication failed" error

**Problem**: ACR credentials are invalid

**Solution**:
```bash
# Regenerate ACR credentials
az acr credential renew --name <acr-name> --password-name password

# Get new credentials
az acr credential show --name <acr-name>

# Update ACR_PASSWORD secret in GitHub
```

### "Resource group not found" error

**Problem**: AZURE_RESOURCE_GROUP doesn't match actual resource group

**Solution**:
```bash
# List resource groups
az group list --query "[].name" -o table

# Update AZURE_RESOURCE_GROUP secret with correct name
```

---

## Security Best Practices

1. **Never commit secrets to Git**
   - Add `azure-credentials.json` to `.gitignore` (already done)
   - Don't log secret values in code

2. **Rotate credentials regularly**
   ```bash
   # Rotate service principal
   az ad sp credential reset --id <app-id>
   
   # Rotate ACR credentials
   az acr credential renew --name <acr-name>
   ```

3. **Use minimal permissions**
   - Service principal should have only required permissions
   - Use Contributor role at resource group level (not subscription)

4. **Monitor secret usage**
   - Check GitHub Actions logs for unauthorized access
   - Review Azure AD sign-in logs

5. **Set up secret scanning**
   - Enable GitHub secret scanning (Settings → Security → Code security)
   - Use tools like git-secrets locally

---

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Azure Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)

---

## Support

Having issues with secrets configuration?

1. Check the [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
2. Verify all prerequisites are met
3. Try running `./scripts/setup-azure.sh` again
4. Open an issue with error logs (remove sensitive data)

---

**Last Updated**: November 2025
