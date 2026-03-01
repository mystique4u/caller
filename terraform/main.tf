terraform {
  backend "remote" {
    organization = "itin"
    workspaces {
      name = "hetznercloud"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Create or manage firewall
resource "hcloud_firewall" "vpn_services" {
  name = var.firewall_name

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "8080"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "51820"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "10000"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Create server
resource "hcloud_server" "vm" {
  name        = "vpn-services-server"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = var.server_location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  firewall_ids = [hcloud_firewall.vpn_services.id]
  ssh_keys     = var.ssh_key_ids

  labels = {
    app     = "vpn-services"
    managed = "terraform"
  }

  lifecycle {
    ignore_changes = [location]
  }
}


# Use existing DNS Zone (created manually in Hetzner Console)
data "hcloud_zone" "domain" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# DNS A Record for root domain
resource "hcloud_zone_record" "root" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "@"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# DNS AAAA Record for root domain (IPv6)
resource "hcloud_zone_record" "root_ipv6" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "@"
  type  = "AAAA"
  value = hcloud_server.vm.ipv6_address
}

# DNS A Record for www subdomain
resource "hcloud_zone_record" "www" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "www"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# DNS A Record for wireguard subdomain
resource "hcloud_zone_record" "wireguard" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "vpn"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# DNS A Record for Jitsi Meet subdomain (kept as 'galene' resource name to avoid DNS recreation)
resource "hcloud_zone_record" "galene" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "meet"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# DNS A Record for Matrix homeserver
resource "hcloud_zone_record" "matrix" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "matrix"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# DNS A Record for Element web client
resource "hcloud_zone_record" "element" {
  count = var.domain_name != "" ? 1 : 0
  zone  = data.hcloud_zone.domain[0].name
  name  = "chat"
  type  = "A"
  value = hcloud_server.vm.ipv4_address
}

# Outputs
output "public_ip" {
  description = "The public IPv4 address of the VM"
  value       = hcloud_server.vm.ipv4_address
}

output "public_ipv6" {
  description = "The public IPv6 address of the VM"
  value       = hcloud_server.vm.ipv6_address
}

output "server_id" {
  description = "The server ID"
  value       = hcloud_server.vm.id
}

output "firewall_id" {
  description = "The firewall ID"
  value       = hcloud_firewall.vpn_services.id
}

output "domain_name" {
  description = "The configured domain name"
  value       = var.domain_name != "" ? var.domain_name : "Not configured"
}

output "dns_zone_id" {
  description = "The DNS zone ID"
  value       = var.domain_name != "" ? data.hcloud_zone.domain[0].id : "N/A"
}

output "nameservers" {
  description = "Nameservers for the domain"
  value       = var.domain_name != "" ? ["hydrogen.ns.hetzner.com", "oxygen.ns.hetzner.com", "helium.ns.hetzner.de"] : []
}

# Variables
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# Uncomment if you want to pass DNS token as a variable (otherwise use env var HETZNER_DNS_TOKEN)
# variable "hetzner_dns_token" {
#   description = "Hetzner DNS API token (for DNS record management)"
#   type        = string
#   sensitive   = true
# }

variable "firewall_name" {
  description = "Name of the Hetzner firewall"
  type        = string
  default     = "vpn-services-firewall"
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the server"
  type        = list(number)
  default     = []
}

variable "domain_name" {
  description = "Domain name for the services (e.g., example.com)"
  type        = string
  default     = ""
}

variable "server_location" {
  description = "Hetzner datacenter location (nbg1, fsn1, hel1, ash)"
  type        = string
  default     = "nbg1"
}
