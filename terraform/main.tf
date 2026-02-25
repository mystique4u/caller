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
  token = var.hcloud_token # Hetzner Cloud API token
}

# Data block to retrieve the existing firewall by name
data "hcloud_firewall" "existing" {
  name = var.firewall_name # Firewall name to attach
}

# Hetzner Cloud VM resource with WireGuard pre-installed
resource "hcloud_server" "vm" {
  name        = "wireguard-vpn-server"
  server_type = "cx22"
  image       = "wireguard" # Pre-configured WireGuard image from Hetzner
  location    = "nbg1"

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true # WireGuard supports IPv6
  }

  firewall_ids = [data.hcloud_firewall.existing.id]

  # SSH keys for root access (WireGuard image uses root initially)
  ssh_keys = var.ssh_key_ids

  labels = {
    app     = "wireguard"
    managed = "terraform"
  }
}

# Output the public IPv4 address of the created VM
output "public_ip" {
  description = "The public IPv4 address of the VM"
  value       = hcloud_server.vm.ipv4_address
  sensitive   = true
}

# Output the public IPv6 address of the created VM
output "public_ipv6" {
  description = "The public IPv6 address of the VM"
  value       = hcloud_server.vm.ipv6_address
  sensitive   = true
}

# Output server ID for reference
output "server_id" {
  description = "The server ID"
  value       = hcloud_server.vm.id
}

# Variables
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "firewall_name" {
  description = "Name of the Hetzner firewall to apply"
  type        = string
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs to add to the server"
  type        = list(number)
  default     = []
}

variable "domain_name" {
  description = "Domain name for WireGuard UI (optional)"
  type        = string
  default     = ""
}