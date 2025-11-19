# CustomGPT-RAG Azure Deployment Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                           │
│                                                                      │
│  ┌──────────┐      ┌──────────┐      ┌──────────────┐             │
│  │   Code   │  →   │   Git    │  →   │   GitHub     │             │
│  │  Changes │      │  Commit  │      │   Push       │             │
│  └──────────┘      └──────────┘      └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      GitHub Actions (CI/CD)                          │
│                                                                      │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐              │
│  │   Test &    │ → │   Build     │ → │   Push to   │              │
│  │   Lint      │   │   Docker    │   │     ACR     │              │
│  └─────────────┘   └─────────────┘   └─────────────┘              │
│         ↓                                    ↓                      │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐              │
│  │  Terraform  │ → │   Apply     │ → │   Deploy    │              │
│  │    Plan     │   │    Infra    │   │   Verify    │              │
│  └─────────────┘   └─────────────┘   └─────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure Resources                               │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Resource Group: customgpt-rag-prod-rg                       │  │
│  │                                                              │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  Azure Container Registry (ACR)                        │ │  │
│  │  │  • Stores Docker images                               │ │  │
│  │  │  • Version tagged (latest, main-sha, etc.)            │ │  │
│  │  │  • Geo-replication (optional)                         │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                           ↓                                  │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  App Service Plan (P1v3)                              │ │  │
│  │  │  • Linux-based                                        │ │  │
│  │  │  • 2 vCPU, 8 GB RAM                                   │ │  │
│  │  │  • Auto-scaling capable                               │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                           ↓                                  │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  App Service (Linux Container)                        │ │  │
│  │  │  ┌──────────────────────────────────────────────────┐ │ │  │
│  │  │  │  CustomGPT-RAG Container                         │ │ │  │
│  │  │  │  • API Server (Port 5110)                        │ │ │  │
│  │  │  │  • UI Server (Port 5111)                         │ │ │  │
│  │  │  │  • Health Checks Active                          │ │ │  │
│  │  │  └──────────────────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                           ↓                                  │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  Azure Storage Account                                │ │  │
│  │  │  • Blob: source-documents (User uploads)              │ │  │
│  │  │  • Blob: database (ChromaDB vectors)                  │ │  │
│  │  │  • Blob: models (HuggingFace cache)                   │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                           ↓                                  │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  Azure Key Vault                                      │ │  │
│  │  │  • ACR Credentials                                    │ │  │
│  │  │  • API Keys (if needed)                               │ │  │
│  │  │  • Managed Identity Access                            │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                           ↓                                  │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  Application Insights (Optional)                      │ │  │
│  │  │  • Request Tracking                                   │ │  │
│  │  │  • Performance Metrics                                │ │  │
│  │  │  • Error Logging                                      │ │  │
│  │  │  • Custom Telemetry                                   │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                          End Users                                   │
│                                                                      │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐           │
│  │   Browser    │ → │   HTTPS      │ → │ App Service  │           │
│  │   Access     │   │   (SSL/TLS)  │   │     URL      │           │
│  └──────────────┘   └──────────────┘   └──────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

## Container Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Docker Container: CustomGPT-RAG                 │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐│
│  │  API Server Process (Port 5110)                        ││
│  │  ┌──────────────────────────────────────────────────┐ ││
│  │  │  Flask API                                       │ ││
│  │  │  • /health (Health check)                        │ ││
│  │  │  • /api/prompt_route (Query processing)          │ ││
│  │  │  • /api/save_document (Upload)                   │ ││
│  │  │  • /api/run_ingest (Indexing)                    │ ││
│  │  │  • /api/delete_source (Cleanup)                  │ ││
│  │  └──────────────────────────────────────────────────┘ ││
│  │                       ↓                                ││
│  │  ┌──────────────────────────────────────────────────┐ ││
│  │  │  LangChain Processing Layer                      │ ││
│  │  │  • Document Loading                              │ ││
│  │  │  • Text Chunking                                 │ ││
│  │  │  • Embedding Generation                          │ ││
│  │  │  • Vector Storage (ChromaDB)                     │ ││
│  │  │  • Retrieval QA Chain                            │ ││
│  │  └──────────────────────────────────────────────────┘ ││
│  │                       ↓                                ││
│  │  ┌──────────────────────────────────────────────────┐ ││
│  │  │  HuggingFace Transformers                        │ ││
│  │  │  • LLM: Llama-2-7b-chat-hf                       │ ││
│  │  │  • Embeddings: instructor-large                  │ ││
│  │  │  • Device: CPU/CUDA                              │ ││
│  │  └──────────────────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌────────────────────────────────────────────────────────┐│
│  │  UI Server Process (Port 5111)                         ││
│  │  ┌──────────────────────────────────────────────────┐ ││
│  │  │  Flask UI                                        │ ││
│  │  │  • Document Upload Interface                     │ ││
│  │  │  • Chat Interface                                │ ││
│  │  │  • Response Display                              │ ││
│  │  │  • API Communication                             │ ││
│  │  └──────────────────────────────────────────────────┘ ││
│  └────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌────────────────────────────────────────────────────────┐│
│  │  Mounted Volumes (Azure Blob Storage)                  ││
│  │  • /app/SOURCE_DOCUMENTS → source-documents container  ││
│  │  • /app/DB → database container                        ││
│  │  • /app/models → models container                      ││
│  └────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline Flow

```
┌──────────────┐
│  Git Push    │
│  to GitHub   │
└──────┬───────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 1: Test                                    │
│  ┌────────────────────────────────────────────┐  │
│  │  • Checkout code                           │  │
│  │  • Setup Python 3.10                       │  │
│  │  • Install dependencies                    │  │
│  │  • Run flake8 linting                      │  │
│  │  • Run pytest (if tests exist)             │  │
│  │  • Generate coverage report                │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 2: Build                                   │
│  ┌────────────────────────────────────────────┐  │
│  │  • Setup Docker Buildx                     │  │
│  │  • Login to Azure Container Registry       │  │
│  │  • Extract metadata (tags)                 │  │
│  │  • Build Docker image                      │  │
│  │  • Push to ACR                             │  │
│  │  • Cache layers for faster builds          │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 3: Terraform Plan                          │
│  ┌────────────────────────────────────────────┐  │
│  │  • Checkout code                           │  │
│  │  • Setup Terraform                         │  │
│  │  • Azure login (service principal)         │  │
│  │  • Determine environment (dev/prod)        │  │
│  │  • Terraform init                          │  │
│  │  • Terraform validate                      │  │
│  │  • Terraform plan                          │  │
│  │  • Upload plan artifact                    │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 4: Terraform Apply                         │
│  ┌────────────────────────────────────────────┐  │
│  │  • Wait for approval (prod only)           │  │
│  │  • Download plan artifact                  │  │
│  │  • Terraform init                          │  │
│  │  • Terraform apply (auto-approve)          │  │
│  │  • Save outputs (URLs, names, etc.)        │  │
│  │  • Upload outputs artifact                 │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 5: Deploy                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  • Azure login                             │  │
│  │  • Extract app service name from outputs   │  │
│  │  • Restart app service (pulls new image)   │  │
│  │  • Wait for restart                        │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│  Stage 6: Health Check                            │
│  ┌────────────────────────────────────────────┐  │
│  │  • Get app URL from outputs                │  │
│  │  • Attempt /health endpoint (10 tries)     │  │
│  │  • 30s between attempts                    │  │
│  │  • Verify 200 OK response                  │  │
│  │  • Fail deployment if unhealthy            │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
       │
       ↓
┌──────────────┐
│  Deployment  │
│   Complete   │
└──────────────┘
```

## Data Flow

```
┌────────────┐
│   User     │
│  Uploads   │
│ Document   │
└─────┬──────┘
      │
      ↓
┌─────────────────────────────────┐
│  UI Server (5111)                │
│  • Receives file                 │
│  • Validates format              │
│  • Sends to API                  │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  API Server (5110)               │
│  • Saves to SOURCE_DOCUMENTS     │
│  • Triggers ingestion            │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  ingest.py                       │
│  • Loads document                │
│  • Chunks text                   │
│  • Generates embeddings          │
│  • Stores in ChromaDB            │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  Azure Blob Storage              │
│  • SOURCE_DOCUMENTS/file.pdf     │
│  • DB/chromadb/...               │
└─────────────────────────────────┘

┌────────────┐
│   User     │
│   Query    │
└─────┬──────┘
      │
      ↓
┌─────────────────────────────────┐
│  UI Server (5111)                │
│  • Receives query                │
│  • Sends to API                  │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  API Server (5110)               │
│  • Receives query                │
│  • Passes to QA chain            │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  RetrievalQA Chain               │
│  • Embeds query                  │
│  • Searches ChromaDB             │
│  • Retrieves relevant docs       │
│  • Passes to LLM                 │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  LLM (Llama-2)                   │
│  • Generates response            │
│  • Uses retrieved context        │
│  • Returns answer                │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  API Server (5110)               │
│  • Formats response              │
│  • Includes sources              │
│  • Returns JSON                  │
└─────────────┬───────────────────┘
              │
              ↓
┌─────────────────────────────────┐
│  UI Server (5111)                │
│  • Displays answer               │
│  • Shows sources                 │
│  • Formats for user              │
└─────────────┬───────────────────┘
              │
              ↓
┌────────────┐
│   User     │
│  Receives  │
│  Answer    │
└────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────┐
│  GitHub Secrets (Encrypted)                      │
│  • AZURE_CREDENTIALS (Service Principal)         │
│  • ACR_LOGIN_SERVER                              │
│  • ACR_USERNAME                                  │
│  • ACR_PASSWORD                                  │
│  • AZURE_RESOURCE_GROUP                          │
└─────────────┬───────────────────────────────────┘
              │ (Secure transmission)
              ↓
┌─────────────────────────────────────────────────┐
│  GitHub Actions Runner                           │
│  • Temporary credentials                         │
│  • Isolated execution                            │
│  • Audit logs                                    │
└─────────────┬───────────────────────────────────┘
              │ (Azure AD Authentication)
              ↓
┌─────────────────────────────────────────────────┐
│  Azure Active Directory                          │
│  • Service Principal Authentication              │
│  • RBAC Policies                                 │
│  • Managed Identities                            │
└─────────────┬───────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────┐
│  Azure Key Vault                                 │
│  • Secrets storage                               │
│  • Access policies                               │
│  • Audit logging                                 │
│  • Soft delete enabled                           │
└─────────────┬───────────────────────────────────┘
              │ (Managed Identity)
              ↓
┌─────────────────────────────────────────────────┐
│  App Service                                     │
│  • System-assigned managed identity              │
│  • HTTPS only                                    │
│  • IP restrictions (optional)                    │
│  • Network security groups                       │
└─────────────────────────────────────────────────┘
```

## Monitoring & Logging

```
┌─────────────────────────────────────────────────┐
│  Application                                     │
│  • Request logs                                  │
│  • Error traces                                  │
│  • Custom metrics                                │
└─────────────┬───────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────┐
│  Application Insights                            │
│  ┌───────────────────────────────────────────┐  │
│  │  Live Metrics                             │  │
│  │  • Request rate                           │  │
│  │  • Response time                          │  │
│  │  • Failure rate                           │  │
│  │  • CPU/Memory usage                       │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  Logs                                     │  │
│  │  • Application logs                       │  │
│  │  • Exception traces                       │  │
│  │  • Custom events                          │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  Alerts                                   │  │
│  │  • High error rate                        │  │
│  │  • Slow response time                     │  │
│  │  • Service availability                   │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────┐
│  Azure Portal Dashboard                          │
│  • Visual metrics                                │
│  • Query logs                                    │
│  • Configure alerts                              │
└─────────────────────────────────────────────────┘
```

---

**Legend:**
- → : Data flow or process flow
- ↓ : Sequential step
- ┌─┐ : Component or container boundary
- │ │ : Grouping or encapsulation
