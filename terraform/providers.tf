terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "zshzebra"
    workspaces {
      name = ["infrastructure"]
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate restic backup password (persists in state)
resource "random_password" "restic" {
  length  = 32
  special = false
}

provider "hcloud" {
  token = var.hetzner_api_token
}

provider "linode" {
  token = var.linode_api_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
