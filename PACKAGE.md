# CustomGPT-RAG Azure Deployment Package

## 📦 Package Overview

This deployment package provides a complete, production-ready solution for deploying CustomGPT-RAG to Azure using:

- **Docker** for containerization
- **Azure Container Registry** for image storage
- **Azure App Service** for hosting
- **Terraform** for infrastructure as code
- **GitHub Actions** for CI/CD automation

## 📁 Package Contents

```
CustomGPT-RAG/
├── Dockerfile                          # Multi-stage container build
├── .dockerignore                       # Docker build exclusions
├── docker-compose.yml                  # Local development setup
├── .env.example                        # Environment configuration template
├── .gitignore                          # Git exclusions (updated)
│
├── .github/
│   └── workflows/
│       ├── ci-cd.yml                  # Main CI/CD pipeline
│       ├── terraform-destroy.yml      # Infrastructure teardown
│       └── docker-test.yml            # Docker build testing
│
├── terraform/
│   ├── main.tf                        # Terraform provider configuration
│   ├── variables.tf                   # Variable definitions
│   ├── resources.tf                   # Azure resource definitions
│   ├── outputs.tf                     # Output values
│   ├── terraform.dev.tfvars          # Development configuration
│   └── terraform.prod.tfvars         # Production configuration
│
├── scripts/
│   ├── setup-azure.sh                # Initial Azure setup
│   ├── deploy.sh                      # Deployment automation
│   ├── cleanup.sh                     # Infrastructure cleanup
│   └── README.md                      # Scripts documentation
│
├── DEPLOYMENT.md                      # Comprehensive deployment guide
├── QUICKSTART.md                      # Quick start guide
└── PACKAGE.md                         # This file
```

## 🎯 Key Features

### 1. Containerization
- **Production-optimized Dockerfile** with multi-stage build
- Health checks and proper signal handling
- Optimized layer caching
- Support for both API and UI servers

### 2. Azure Infrastructure
- **Container Registry** for secure image storage
- **App Service** with Linux containers
- **Storage Account** for persistent data (documents, DB, models)
- **Key Vault** for secrets management
- **Application Insights** for monitoring (optional)

### 3. CI/CD Pipeline
- **Automated testing** with linting and unit tests
- **Docker build and push** to ACR
- **Terraform automation** for infrastructure
- **Deployment verification** with health checks
- **Environment separation** (dev/prod)

### 4. Developer Experience
- **Local development** with Docker Compose
- **Automated scripts** for common tasks
- **Comprehensive documentation**
- **Environment configuration** templates

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# 1. Run setup script
./scripts/setup-azure.sh

# 2. Configure GitHub secrets (see output from step 1)

# 3. Deploy
./scripts/deploy.sh --env dev
```

### Option 2: Manual Setup

See [QUICKSTART.md](QUICKSTART.md) for step-by-step instructions.

### Option 3: GitHub Actions Only

1. Configure GitHub secrets
2. Push to `main` branch
3. GitHub Actions handles everything

## 📋 Prerequisites Checklist

- [ ] Azure subscription with Contributor role
- [ ] Azure CLI installed and configured
- [ ] Terraform v1.6+ installed
- [ ] Docker installed and running
- [ ] GitHub repository with Actions enabled
- [ ] Basic understanding of Azure, Docker, and Terraform

## 🏗️ Architecture

### High-Level Flow

```
Developer Push → GitHub Actions → Build Docker Image → Push to ACR
                                       ↓
                              Terraform Infrastructure
                                       ↓
                           Deploy to App Service → Health Check
```

### Azure Resources

| Resource | Purpose | Cost (Est.) |
|----------|---------|-------------|
| Container Registry | Docker image storage | $5-20/month |
| App Service Plan | Compute resources | $60-145/month |
| Storage Account | Persistent data | $5-10/month |
| Key Vault | Secrets management | $1/month |
| Application Insights | Monitoring (optional) | $10/month |

**Total: $70-185/month** (dev to prod)

## 🔒 Security Features

1. **Secrets Management**
   - Azure Key Vault integration
   - GitHub Secrets for CI/CD
   - No hardcoded credentials

2. **Network Security**
   - Private container registry
   - HTTPS by default
   - Health check endpoints

3. **Access Control**
   - Azure RBAC
   - Service principal authentication
   - Managed identities

## 📊 Monitoring

### Built-in Health Checks
- Container health endpoint at `/health`
- Automatic restart on failure
- Deployment verification in CI/CD

### Optional Application Insights
- Request tracking
- Performance metrics
- Error logging
- Custom telemetry

## 🔄 CI/CD Workflow

### On Push to Main
1. ✅ Run tests and linting
2. 🐳 Build Docker image
3. 📤 Push to Azure Container Registry
4. 📋 Plan Terraform changes
5. 🏗️ Apply infrastructure (with approval)
6. 🚀 Deploy to App Service
7. 🏥 Health check verification
8. 📢 Notify results

### Branch Strategy
- `main` → Production (requires approval)
- `develop` → Development (auto-deploy)
- Pull requests → Docker build test only

## 🛠️ Common Operations

### Deploy to Development
```bash
./scripts/deploy.sh --env dev
```

### Deploy to Production
```bash
./scripts/deploy.sh --env prod
```

### View Logs
```bash
az webapp log tail --name <app-name> --resource-group <rg-name>
```

### Scale Up
```bash
az appservice plan update --name <plan-name> --resource-group <rg-name> --sku P2v3
```

### Destroy Infrastructure
```bash
./scripts/cleanup.sh --env dev
```

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide with troubleshooting
- **[QUICKSTART.md](QUICKSTART.md)** - Fast-track setup in 5 minutes
- **[scripts/README.md](scripts/README.md)** - Automation scripts documentation
- **[terraform/](terraform/)** - Infrastructure as code with comments

## 🔧 Customization

### Environment Variables

Edit `.env` or `terraform/*.tfvars`:

```bash
# Model configuration
MODEL_ID=NousResearch/Llama-2-7b-chat-hf
EMBEDDING_MODEL_NAME=hkunlp/instructor-large
DEVICE_TYPE=cpu

# Scaling
app_service_plan_sku=P2v3
```

### Infrastructure Scaling

```hcl
# terraform/terraform.prod.tfvars
app_service_plan_sku = "P2v3"  # More CPU/RAM
acr_sku = "Premium"            # Geo-replication
```

### Docker Optimization

```dockerfile
# Dockerfile
# Use GPU support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04
```

## 🧪 Testing

### Local Testing
```bash
docker-compose up -d
curl http://localhost:5110/health
```

### Pre-deployment Testing
```bash
# Run tests
pytest

# Lint code
flake8 .

# Build Docker
docker build -t test .
```

### Post-deployment Testing
```bash
# Health check
curl https://<app-url>/health

# Integration test
curl -X POST https://<app-url>/api/prompt_route \
  -F "user_prompt=test query"
```

## 🐛 Troubleshooting

### Common Issues

1. **Container won't start**: Check logs with `az webapp log tail`
2. **Health check fails**: Verify API is running on port 5110
3. **Terraform errors**: Check Azure quotas and permissions
4. **GitHub Actions fails**: Verify all secrets are configured

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.

## 📈 Performance Optimization

### Application Level
- Use smaller models for faster inference
- Implement caching for embeddings
- Optimize document chunking

### Infrastructure Level
- Scale App Service Plan for more resources
- Use Premium App Service for better performance
- Enable autoscaling based on metrics

### Cost Optimization
- Use development tier for testing
- Schedule App Service stop/start
- Clean up unused resources

## 🔄 Update Strategy

### Application Updates
```bash
# Update code
git commit -am "Update feature"
git push origin main

# GitHub Actions deploys automatically
```

### Infrastructure Updates
```bash
# Edit terraform files
cd terraform
terraform plan -var-file=terraform.prod.tfvars
terraform apply
```

### Model Updates
Edit `constants.py`:
```python
MODEL_ID = "new-model-id"
```

## 📞 Support

### Resources
- **Issues**: [GitHub Issues](https://github.com/Jakee4488/CustomGPT-RAG/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Jakee4488/CustomGPT-RAG/discussions)
- **Azure Docs**: [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- **Terraform Docs**: [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Getting Help
1. Check [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
2. Search existing GitHub issues
3. Enable debug logging: `export TF_LOG=DEBUG`
4. Share logs when asking for help

## 🎓 Learning Resources

- **Docker**: [Official Docs](https://docs.docker.com/)
- **Terraform**: [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- **GitHub Actions**: [Documentation](https://docs.github.com/en/actions)
- **Azure**: [Microsoft Learn](https://docs.microsoft.com/en-us/learn/azure/)

## ✅ Deployment Checklist

- [ ] Azure subscription ready
- [ ] All prerequisites installed
- [ ] Run `./scripts/setup-azure.sh`
- [ ] Configure GitHub secrets
- [ ] Review and customize `terraform/*.tfvars`
- [ ] Test locally with Docker Compose
- [ ] Deploy to development
- [ ] Verify health checks
- [ ] Test application functionality
- [ ] Deploy to production
- [ ] Set up monitoring
- [ ] Document custom configuration

## 🎉 Success Criteria

Your deployment is successful when:

1. ✅ GitHub Actions pipeline completes without errors
2. ✅ Health endpoint returns 200 OK
3. ✅ UI is accessible at the App Service URL
4. ✅ API responds to test queries
5. ✅ Documents can be uploaded and processed
6. ✅ Logs are accessible in Azure Portal

## 📝 License

This deployment package is part of the CustomGPT-RAG project.
See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Improvements to this deployment solution are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Package Version**: 1.0.0  
**Last Updated**: November 2025  
**Maintained By**: Jakee4488

For the latest updates, visit: https://github.com/Jakee4488/CustomGPT-RAG
