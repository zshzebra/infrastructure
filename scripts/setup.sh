#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR/terraform"
ANSIBLE_DIR="$ROOT_DIR/ansible"

echo -e "${GREEN}=== Infrastructure Setup ===${NC}"

# Step 1: Terraform
cd "$TERRAFORM_DIR"

if [[ "$1" == "--apply" || "$1" == "-a" ]]; then
    echo -e "${YELLOW}Running terraform init...${NC}"
    terraform init

    echo -e "${YELLOW}Running terraform apply...${NC}"
    terraform apply
fi

# Step 2: Export terraform outputs
echo -e "${YELLOW}Exporting Terraform outputs...${NC}"
terraform output -json > "$ANSIBLE_DIR/terraform_outputs.json"
echo -e "${GREEN}Exported to ansible/terraform_outputs.json${NC}"

# Step 3: Get VPS IP
VPS_IP=$(terraform output -raw server_ipv4 2>/dev/null || echo "")

if [[ -z "$VPS_IP" ]]; then
    echo -e "${RED}Error: Could not get server IP. Have you run 'terraform apply'?${NC}"
    exit 1
fi

echo -e "${GREEN}VPS IP: $VPS_IP${NC}"

# Step 4: Display next steps
echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Export the VPS_IP environment variable:"
echo -e "     ${YELLOW}export VPS_IP=$VPS_IP${NC}"
echo ""
echo "  2. Bootstrap the server:"
echo -e "     ${YELLOW}cd $ANSIBLE_DIR && ansible-playbook playbooks/bootstrap.yml${NC}"
echo ""
echo "  3. Deploy services:"
echo -e "     ${YELLOW}ansible-playbook playbooks/deploy-service.yml -e service_name=vaultwarden${NC}"
echo ""

# Optional: Write env file for sourcing
ENV_FILE="$ROOT_DIR/.env"
echo "export VPS_IP=$VPS_IP" > "$ENV_FILE"
echo -e "${GREEN}Environment saved to .env - source it with: source $ROOT_DIR/.env${NC}"
