# SSH Key - shared across all environments (same key, no env prefix)
resource "hcloud_ssh_key" "main" {
  name       = "${var.server_name}-key"
  public_key = file(var.ssh_public_key_path)

  lifecycle {
    # Prevent destroy if key is used by other environments
    prevent_destroy = false
  }
}

# Firewall - Minimal since Cloudflare tunnels handle ingress
resource "hcloud_firewall" "main" {
  name = "${local.env_prefix}${var.server_name}-firewall"

  # Allow SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Allow ICMP for ping/diagnostics
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound (Docker pulls, Cloudflare tunnels, backups)
  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Server
resource "hcloud_server" "main" {
  name         = "${local.env_prefix}${var.server_name}"
  image        = var.server_image
  server_type  = var.server_type
  location     = var.server_location
  ssh_keys     = [hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.main.id]

  labels = {
    environment = local.env
    managed_by  = "terraform"
  }

  # Cloud-init for initial setup
  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - python3
      - python3-pip
    EOF
}

# Volume for Docker data
resource "hcloud_volume" "docker_data" {
  name     = "${local.env_prefix}${var.server_name}-docker-data"
  size     = var.volume_size
  location = var.server_location
  format   = "ext4"

  labels = {
    environment = local.env
    managed_by  = "terraform"
    purpose     = "docker-data"
  }
}

# Attach volume to server
resource "hcloud_volume_attachment" "docker_data" {
  volume_id = hcloud_volume.docker_data.id
  server_id = hcloud_server.main.id
  automount = false # Ansible will handle mounting
}
