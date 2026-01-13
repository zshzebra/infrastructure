# Infrastructure

Terraform + Ansible infrastructure for self-hosted services with Cloudflare Tunnels.

## Architecture

- **Hetzner**: VPS + Volume (Docker data storage)
- **Linode**: S3-compatible Object Storage (backups)
- **Cloudflare**: Zero Trust Tunnels (secure access, no exposed ports)

## Services

| Service | Subdomain (dev) | Subdomain (prod) |
|---------|-----------------|------------------|
| Vaultwarden | vw-dev.zshzebra.xyz | vw.zshzebra.xyz |
| Open WebUI | openwebui-dev.zshzebra.xyz | openwebui.zshzebra.xyz |
| Calibre-Web | calibre-dev.zshzebra.xyz | calibre.zshzebra.xyz |

## Prerequisites

- Terraform >= 1.0
- Ansible
- API tokens for: Hetzner, Linode, Cloudflare

## Initial Deployment

### 1. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your API tokens and settings
```

### 2. Select Environment

```bash
# For dev environment
terraform workspace new dev
terraform workspace select dev

# For prod environment
terraform workspace select default
# or
terraform workspace new prod
terraform workspace select prod
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform apply
```

### 4. Export Outputs for Ansible

```bash
terraform output -json > ../ansible/terraform_outputs.json
```

### 5. Bootstrap Server

```bash
export VPS_IP=$(terraform output -raw server_ipv4)
cd ../ansible
ansible-playbook playbooks/bootstrap.yml
```

### 6. Deploy Services

```bash
# Deploy individual service
ansible-playbook playbooks/deploy-service.yml -e service_name=vaultwarden

# Deploy all services
for svc in vaultwarden openwebui calibre-web; do
  ansible-playbook playbooks/deploy-service.yml -e service_name=$svc
done
```

## Quick Setup Script

After initial terraform.tfvars configuration:

```bash
./scripts/setup.sh --apply
source .env
cd ansible
ansible-playbook playbooks/bootstrap.yml
```

## Day-to-Day Operations

### Update a Service

```bash
cd ansible
ansible-playbook playbooks/update-service.yml -e service_name=vaultwarden
```

### Backup a Service

```bash
ansible-playbook playbooks/backup-service.yml -e service_name=vaultwarden
```

### Restore from Backup

```bash
# Restore latest snapshot
ansible-playbook playbooks/restore-service.yml -e service_name=vaultwarden

# Restore specific snapshot
ansible-playbook playbooks/restore-service.yml -e service_name=vaultwarden -e snapshot_id=abc123
```

### Delete a Service

```bash
ansible-playbook playbooks/delete-service.yml -e service_name=vaultwarden
```

## Destroy Infrastructure

### 1. Stop All Containers

```bash
ssh root@$(cd terraform && terraform output -raw server_ipv4) \
  "docker stop \$(docker ps -q) 2>/dev/null; docker rm \$(docker ps -aq) 2>/dev/null"
```

### 2. Empty S3 Bucket

```bash
cd terraform

# Create temp access key
linode-cli object-storage keys-create --label temp-delete \
  --bucket_access '[{"cluster":"sg-sin-2","bucket_name":"dev-docker-backups","permissions":"read_write"}]'

# Use the output credentials
export AWS_ACCESS_KEY_ID=<access_key>
export AWS_SECRET_ACCESS_KEY=<secret_key>

# Delete all objects
aws s3 rm s3://dev-docker-backups --recursive --endpoint-url https://sg-sin-1.linodeobjects.com

# Delete temp key (use the ID from keys-create output)
linode-cli object-storage keys-delete <key_id>
```

### 3. Destroy Terraform Resources

```bash
terraform destroy
```

### 4. Clean Up Local State (Optional)

```bash
rm ../ansible/terraform_outputs.json
rm -rf ../ansible/.ansible_cache
```

## Directory Structure

```
infrastructure/
├── terraform/           # Infrastructure provisioning
│   ├── providers.tf     # Provider configuration
│   ├── variables.tf     # Variable definitions
│   ├── terraform.tfvars # Your configuration (gitignored)
│   ├── hetzner.tf       # VPS, Volume, Firewall, SSH key
│   ├── linode.tf        # S3 bucket and access keys
│   ├── cloudflare.tf    # Tunnels and DNS records
│   └── outputs.tf       # Outputs for Ansible
├── ansible/             # Server configuration
│   ├── ansible.cfg      # Ansible configuration
│   ├── inventory/       # Host and variable definitions
│   ├── playbooks/       # Deployment playbooks
│   └── roles/           # Reusable roles
├── services/            # Docker Compose templates
│   ├── vaultwarden/
│   ├── openwebui/
│   └── calibre-web/
└── scripts/
    └── setup.sh         # Quick setup script
```

## Environment Variables

The setup script creates a `.env` file you can source:

```bash
source .env  # Sets VPS_IP
```

## Workspaces

Terraform workspaces isolate environments:

| Workspace | Prefix | Example hostname |
|-----------|--------|------------------|
| default/prod | (none) | vw.zshzebra.xyz |
| dev | dev- | vw-dev.zshzebra.xyz |
| staging | staging- | vw-staging.zshzebra.xyz |

Each workspace creates separate:
- Hetzner VPS and Volume
- Linode S3 bucket
- Cloudflare Tunnels and DNS records
