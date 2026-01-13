# Cloudflare Tunnels for each service

# Create a tunnel for each service
resource "cloudflare_zero_trust_tunnel_cloudflared" "service_tunnels" {
  for_each   = var.services
  account_id = var.cloudflare_account_id
  name       = "${local.env_prefix}${each.key}"
  config_src = "cloudflare"
}

# Get the tunnel token for each service
data "cloudflare_zero_trust_tunnel_cloudflared_token" "service_tokens" {
  for_each   = var.services
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.service_tunnels[each.key].id
}

# Create DNS CNAME records for each service
# Format: {subdomain}.{env}.zone or {subdomain}.zone for prod
resource "cloudflare_dns_record" "service_dns" {
  for_each = var.services
  zone_id  = var.cloudflare_zone_id
  name     = "${each.value.subdomain}${local.env_suffix}"
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.service_tunnels[each.key].id}.cfargotunnel.com"
  type     = "CNAME"
  ttl      = 1
  proxied  = true
}

# Configure tunnel ingress rules for each service
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "service_configs" {
  for_each   = var.services
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.service_tunnels[each.key].id

  config = {
    ingress = [
      {
        hostname = "${each.value.subdomain}${local.env_suffix}.${var.cloudflare_zone}"
        service  = "http://${each.key}:${each.value.port}"
      },
      {
        # Catch-all rule (required)
        service = "http_status:404"
      }
    ]
  }
}
