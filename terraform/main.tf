terraform {terraform {

  backend "remote" {  backend "remote" {

    organization = "itin"    organization = "itin"

    workspaces {

      name = "hetznercloud"    workspaces {

    }      name = "hetznercloud"

  }    }

  }

  required_providers {

    hcloud = {  required_providers {

      source  = "hetznercloud/hcloud"    hcloud = {

      version = "1.60.1"      source  = "hetznercloud/hcloud"

    }      version = "1.60.1"

  }    }

}  }

}

provider "hcloud" {

  token = var.hcloud_tokenprovider "hcloud" {

}  token = var.hcloud_token # Hetzner Cloud API token

}

data "hcloud_firewall" "existing" {

  name = var.firewall_name# Data block to retrieve the existing firewall by name

}data "hcloud_firewall" "existing" {

  name = var.firewall_name # Firewall name to attach

resource "hcloud_server" "vm" {}

  name        = "vpn-services-server"

  server_type = "cx22"# Hetzner Cloud VM resource with WireGuard pre-installed

  image       = "ubuntu-24.04"resource "hcloud_server" "vm" {

  location    = "nbg1"  name        = "wireguard-vpn-server"

  server_type = "cx23"

  public_net {  image       = "wireguard" # Pre-configured WireGuard image from Hetzner

    ipv4_enabled = true  location    = "nbg1"

    ipv6_enabled = true

  }  public_net {

    ipv4_enabled = true

  firewall_ids = [data.hcloud_firewall.existing.id]    ipv6_enabled = true # WireGuard supports IPv6

  ssh_keys     = var.ssh_key_ids  }



  labels = {  firewall_ids = [data.hcloud_firewall.existing.id]

    app     = "vpn-services"

    managed = "terraform"  # SSH keys for root access (WireGuard image uses root initially)

  }  ssh_keys = var.ssh_key_ids

}

  labels = {

output "public_ip" {    app     = "wireguard"

  description = "The public IPv4 address of the VM"    managed = "terraform"

  value       = hcloud_server.vm.ipv4_address  }

}}



output "public_ipv6" {# Output the public IPv4 address of the created VM

  description = "The public IPv6 address of the VM"output "public_ip" {

  value       = hcloud_server.vm.ipv6_address  description = "The public IPv4 address of the VM"

}  value       = hcloud_server.vm.ipv4_address

  sensitive   = true

output "server_id" {}

  description = "The server ID"

  value       = hcloud_server.vm.id# Output the public IPv6 address of the created VM

}output "public_ipv6" {

  description = "The public IPv6 address of the VM"

variable "hcloud_token" {  value       = hcloud_server.vm.ipv6_address

  description = "Hetzner Cloud API token"  sensitive   = true

  type        = string}

  sensitive   = true

}# Output server ID for reference

output "server_id" {

variable "firewall_name" {  description = "The server ID"

  description = "Name of the Hetzner firewall to apply"  value       = hcloud_server.vm.id

  type        = string}

}

# Variables

variable "ssh_key_ids" {variable "hcloud_token" {

  description = "List of SSH key IDs to add to the server"  description = "Hetzner Cloud API token"

  type        = list(number)  type        = string

  default     = []  sensitive   = true

}}


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