# Hetzner Variables
variable "hetzner_api_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "server_name" {
  description = "Name for the Hetzner VPS"
  type        = string
  default     = "docker-services"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx22" # 2 vCPU, 4GB RAM - headroom over current cx11
}

variable "server_location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "fsn1" # Falkenstein, Germany
}

variable "server_image" {
  description = "OS image for the server"
  type        = string
  default     = "rocky-9"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "volume_size" {
  description = "Size of the Docker data volume in GB"
  type        = number
  default     = 40
}

# Linode Variables
variable "linode_api_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "backup_bucket_name" {
  description = "Name for the Linode Object Storage bucket"
  type        = string
  default     = "docker-backups"
}

variable "backup_bucket_region" {
  description = "Linode Object Storage region"
  type        = string
  default     = "us-east-1" # Newark
}

# Cloudflare Variables
variable "cloudflare_api_token" {
  description = "Cloudflare API token with Tunnel and DNS permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "cloudflare_zone" {
  description = "Domain name (e.g., zshzebra.xyz)"
  type        = string
  default     = "zshzebra.xyz"
}

# Service definitions for tunnels
variable "services" {
  description = "Map of services to deploy with their subdomains and ports"
  type = map(object({
    subdomain = string
    port      = number
  }))
  default = {
    vaultwarden = {
      subdomain = "vw"
      port      = 80
    }
    openwebui = {
      subdomain = "openwebui"
      port      = 8080
    }
    calibre-web = {
      subdomain = "calibre"
      port      = 8083
    }
  }
}

# Environment - uses terraform.workspace by default
# prod workspace = no prefix, other workspaces = prefix
locals {
  env        = terraform.workspace
  is_prod    = local.env == "default" || local.env == "prod"
  env_prefix = local.is_prod ? "" : "${local.env}-"
  env_suffix = local.is_prod ? "" : "-${local.env}"
}
