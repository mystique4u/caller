# WireGuard UI Fix - March 15, 2026

## Problem
The WireGuard UI web interface was unable to automatically reload the WireGuard service configuration when changes were made through the UI. Changes required manual intervention using `wg syncconf`.

## Root Cause
The wireguard-ui Docker container was running on a bridge network (`services_network`), which meant it was in its own network namespace and **could not access the host's WireGuard interface** (wg0).

## Solution

### Changes Made on Server
1. **Changed Network Mode**: Modified wireguard-ui to use `network_mode: host` instead of bridge network
2. **Removed Incompatible Settings**: Removed `sysctls` configuration (not allowed in host network mode)
3. **Removed Traefik Labels**: Removed Docker labels since they don't work with host network mode
4. **Added Traefik Dynamic Configuration**: Created `/opt/services/traefik/dynamic/wireguard-ui.yml` to route traffic via file provider
5. **Updated Traefik**: Added file provider to traefik.toml to read dynamic configurations
6. **Fixed Routing**: Used gateway IP (172.18.0.1) instead of 127.0.0.1 so Traefik can reach the UI

### Changes Made to Ansible Templates
1. Updated [docker-compose.yml.j2](ansible/templates/docker-compose.yml.j2):
   - Changed wireguard-ui to use `network_mode: host`
   - Removed sysctls section
   - Removed networks and labels

2. Created [wireguard-dynamic.yml.j2](ansible/templates/wireguard-dynamic.yml.j2):
   - Traefik file provider configuration for wireguard-ui
   - Routes `vpn.{{ domain_name }}` to http://172.18.0.1:5000

3. Updated [traefik.toml.j2](ansible/templates/traefik.toml.j2):
   - Added file provider with directory `/etc/traefik/dynamic`
   - Enabled watch mode for automatic reload

4. Updated [tasks/traefik.yml](ansible/tasks/traefik.yml):
   - Added task to create dynamic configuration directory
   - Added task to deploy wireguard UI dynamic configuration

## Verification
- ✅ wireguard-ui container can now see host WireGuard interface (`wg show` works)
- ✅ Web interface accessible via https://vpn.itin.buzz
- ✅ Changes made through UI will automatically apply to the WireGuard interface

## Testing
After making changes in the WireGuard UI (adding/editing peers), the configuration should be automatically applied without needing manual `wg syncconf` commands.

## Notes
- The gateway IP (172.18.0.1) is the default Docker bridge gateway for the services network
- Host network mode gives the container full access to the host's network stack
- File provider watches for changes and automatically reloads Traefik configuration
