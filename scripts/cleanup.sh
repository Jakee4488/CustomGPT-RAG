#!/bin/bash

# Cleanup Script for CustomGPT-RAG
# Safely destroys Azure infrastructure

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT="dev"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: ./cleanup.sh --env <dev|prod>"
      exit 1
      ;;
  esac
done

echo -e "${RED}==================================${NC}"
echo -e "${RED}CustomGPT-RAG Cleanup${NC}"
echo -e "${RED}Environment: $ENVIRONMENT${NC}"
echo -e "${RED}==================================${NC}\n"

echo -e "${YELLOW}⚠️  This will destroy all infrastructure for the $ENVIRONMENT environment!${NC}"
echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}\n"

read -p "Type 'destroy' to confirm: " CONFIRM
if [ "$CONFIRM" != "destroy" ]; then
  echo -e "${GREEN}Cleanup cancelled${NC}"
  exit 0
fi

cd terraform

echo -e "${YELLOW}Destroying infrastructure...${NC}"
terraform destroy -var-file="terraform.$ENVIRONMENT.tfvars" -auto-approve

echo -e "${GREEN}✓ Infrastructure destroyed${NC}\n"

cd ..

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Cleanup Complete${NC}"
echo -e "${GREEN}==================================${NC}"
