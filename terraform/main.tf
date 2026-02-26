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
      version = "1.60.1"
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
}

# Create server
resource "hcloud_server" "vm" {
  name        = "vpn-services-server"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "nbg1"

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

# Variables
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

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
