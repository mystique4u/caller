terraform {terraform {terraform {

  backend "remote" {

    organization = "itin"  backend "remote" {  backend "remote" {

    workspaces {

      name = "hetznercloud"    organization = "itin"    organization = "itin"

    }

  }    workspaces {



  required_providers {      name = "hetznercloud"    workspaces {

    hcloud = {

      source  = "hetznercloud/hcloud"    }      name = "hetznercloud"

      version = "1.60.1"

    }  }    }

  }

}  }



provider "hcloud" {  required_providers {

  token = var.hcloud_token

}    hcloud = {  required_providers {



# Create or manage firewall      source  = "hetznercloud/hcloud"    hcloud = {

resource "hcloud_firewall" "vpn_services" {

  name = var.firewall_name      version = "1.60.1"      source  = "hetznercloud/hcloud"



  rule {    }      version = "1.60.1"

    direction = "in"

    protocol  = "tcp"  }    }

    port      = "22"

    source_ips = [}  }

      "0.0.0.0/0",

      "::/0"}

    ]

  }provider "hcloud" {



  rule {  token = var.hcloud_tokenprovider "hcloud" {

    direction = "in"

    protocol  = "tcp"}  token = var.hcloud_token # Hetzner Cloud API token

    port      = "80"

    source_ips = [}

      "0.0.0.0/0",

      "::/0"data "hcloud_firewall" "existing" {

    ]

  }  name = var.firewall_name# Data block to retrieve the existing firewall by name



  rule {}data "hcloud_firewall" "existing" {

    direction = "in"

    protocol  = "tcp"  name = var.firewall_name # Firewall name to attach

    port      = "8080"

    source_ips = [resource "hcloud_server" "vm" {}

      "0.0.0.0/0",

      "::/0"  name        = "vpn-services-server"

    ]

  }  server_type = "cx22"# Hetzner Cloud VM resource with WireGuard pre-installed



  rule {  image       = "ubuntu-24.04"resource "hcloud_server" "vm" {

    direction = "in"

    protocol  = "udp"  location    = "nbg1"  name        = "wireguard-vpn-server"

    port      = "51820"

    source_ips = [  server_type = "cx23"

      "0.0.0.0/0",

      "::/0"  public_net {  image       = "wireguard" # Pre-configured WireGuard image from Hetzner

    ]

  }    ipv4_enabled = true  location    = "nbg1"

}

    ipv6_enabled = true

# Create server

resource "hcloud_server" "vm" {  }  public_net {

  name        = "vpn-services-server"

  server_type = "cx23"    ipv4_enabled = true

  image       = "ubuntu-24.04"

  location    = "nbg1"  firewall_ids = [data.hcloud_firewall.existing.id]    ipv6_enabled = true # WireGuard supports IPv6



  public_net {  ssh_keys     = var.ssh_key_ids  }

    ipv4_enabled = true

    ipv6_enabled = true

  }

  labels = {  firewall_ids = [data.hcloud_firewall.existing.id]

  firewall_ids = [hcloud_firewall.vpn_services.id]

  ssh_keys     = var.ssh_key_ids    app     = "vpn-services"



  labels = {    managed = "terraform"  # SSH keys for root access (WireGuard image uses root initially)

    app     = "vpn-services"

    managed = "terraform"  }  ssh_keys = var.ssh_key_ids

  }

}}



# Outputs  labels = {

output "public_ip" {

  description = "The public IPv4 address of the VM"output "public_ip" {    app     = "wireguard"

  value       = hcloud_server.vm.ipv4_address

}  description = "The public IPv4 address of the VM"    managed = "terraform"



output "public_ipv6" {  value       = hcloud_server.vm.ipv4_address  }

  description = "The public IPv6 address of the VM"

  value       = hcloud_server.vm.ipv6_address}}

}



output "server_id" {

  description = "The server ID"output "public_ipv6" {# Output the public IPv4 address of the created VM

  value       = hcloud_server.vm.id

}  description = "The public IPv6 address of the VM"output "public_ip" {



output "firewall_id" {  value       = hcloud_server.vm.ipv6_address  description = "The public IPv4 address of the VM"

  description = "The firewall ID"

  value       = hcloud_firewall.vpn_services.id}  value       = hcloud_server.vm.ipv4_address

}

  sensitive   = true

# Variables

variable "hcloud_token" {output "server_id" {}

  description = "Hetzner Cloud API token"

  type        = string  description = "The server ID"

  sensitive   = true

}  value       = hcloud_server.vm.id# Output the public IPv6 address of the created VM



variable "firewall_name" {}output "public_ipv6" {

  description = "Name of the Hetzner firewall"

  type        = string  description = "The public IPv6 address of the VM"

  default     = "vpn-services-firewall"

}variable "hcloud_token" {  value       = hcloud_server.vm.ipv6_address



variable "ssh_key_ids" {  description = "Hetzner Cloud API token"  sensitive   = true

  description = "List of SSH key IDs to add to the server"

  type        = list(number)  type        = string}

  default     = []

}  sensitive   = true


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