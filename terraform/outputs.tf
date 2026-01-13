# Hetzner Outputs
output "server_ipv4" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.main.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.main.ipv6_address
}

output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.main.id
}

# Volume Outputs
output "volume_id" {
  description = "Hetzner Volume ID"
  value       = hcloud_volume.docker_data.id
}

output "volume_linux_device" {
  description = "Linux device path for the volume"
  value       = hcloud_volume.docker_data.linux_device
}

output "volume_size" {
  description = "Volume size in GB"
  value       = hcloud_volume.docker_data.size
}

# Linode Outputs
output "s3_endpoint" {
  description = "S3-compatible endpoint URL"
  # hostname is "bucket.cluster.linodeobjects.com", we need just "cluster.linodeobjects.com"
  value       = "https://${replace(linode_object_storage_bucket.backups.hostname, "${linode_object_storage_bucket.backups.label}.", "")}"
}

output "s3_bucket" {
  description = "S3 bucket name"
  value       = linode_object_storage_bucket.backups.label
}

output "s3_access_key" {
  description = "S3 access key"
  value       = linode_object_storage_key.backups.access_key
  sensitive   = true
}

output "s3_secret_key" {
  description = "S3 secret key"
  value       = linode_object_storage_key.backups.secret_key
  sensitive   = true
}

# Cloudflare Tunnel Outputs
output "tunnel_tokens" {
  description = "Map of service name to tunnel token"
  value = {
    for name, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.service_tokens :
    name => token.token
  }
  sensitive = true
}

output "tunnel_hostnames" {
  description = "Map of service name to hostname"
  value = {
    for name, svc in var.services :
    name => "${svc.subdomain}${local.env_suffix}.${var.cloudflare_zone}"
  }
}

# Environment info
output "environment" {
  description = "Current environment/workspace"
  value       = local.env
}

# Restic backup password
output "restic_password" {
  description = "Generated password for restic backups"
  value       = random_password.restic.result
  sensitive   = true
}

# Helper output for Ansible inventory
output "ansible_host_entry" {
  description = "Entry for Ansible inventory"
  value       = "${local.env_prefix}${var.server_name} ansible_host=${hcloud_server.main.ipv4_address}"
}
