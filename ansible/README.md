# Ansible Playbook Structure

## Overview

The playbook has been refactored into a modular structure for better maintainability and organization.

## Directory Structure

```
ansible/
├── playbook-refactored.yml    # New modular main playbook
├── playbook.yml                # Original monolithic playbook (keep for reference)
├── inventory.ini               # Server inventory
├── ansible.cfg                 # Ansible configuration
├── tasks/                      # Task files (modular)
│   ├── system-setup.yml        # System packages, Docker installation
│   ├── wireguard.yml           # WireGuard VPN configuration
│   ├── directories.yml         # Create all service directories
│   ├── traefik.yml             # Traefik reverse proxy setup
│   ├── service-configs.yml     # LiveKit, TURN configurations
│   ├── matrix.yml              # Matrix Synapse configuration
│   ├── services.yml            # Docker Compose deployment & health checks
│   └── backup.yml              # Backup configuration
└── templates/                  # Jinja2 templates
    ├── docker-compose.yml.j2   # Docker Compose configuration
    ├── traefik.toml.j2         # Traefik static configuration
    └── element-config.json.j2  # Element Web configuration
```

## Usage

### Run the full playbook:
```bash
ansible-playbook -i inventory.ini playbook-refactored.yml
```

### Run specific tags only:
```bash
# Only system setup and Docker
ansible-playbook -i inventory.ini playbook-refactored.yml --tags system,docker

# Only Matrix configuration
ansible-playbook -i inventory.ini playbook-refactored.yml --tags matrix

# Only service deployment
ansible-playbook -i inventory.ini playbook-refactored.yml --tags services

# Skip backup configuration
ansible-playbook -i inventory.ini playbook-refactored.yml --skip-tags backup
```

## Available Tags

- `system` - System packages and updates
- `docker` - Docker installation and configuration
- `wireguard`, `vpn` - WireGuard VPN setup
- `directories` - Create service directories
- `traefik`, `proxy` - Traefik reverse proxy
- `config` - General service configurations
- `livekit` - LiveKit SFU configuration
- `turn` - TURN server configuration
- `matrix`, `synapse` - Matrix Synapse setup
- `services`, `docker-compose` - Service deployment
- `backup` - Backup configuration

## Benefits of Refactored Structure

1. **Modularity**: Each component is in its own file
2. **Maintainability**: Easier to find and update specific configurations
3. **Reusability**: Task files can be reused in other playbooks
4. **Selective Execution**: Use tags to run only what you need
5. **Templates**: Large configuration files are now proper Jinja2 templates
6. **Readability**: Main playbook is now ~70 lines instead of >1000
7. **Testing**: Easier to test individual components

## Migration from Old Playbook

The old `playbook.yml` still works. To migrate to the new structure:

1. **Test the new playbook** in a staging environment first
2. **Update your CI/CD** to use `playbook-refactored.yml`
3. **Keep the old playbook** as backup during transition
4. **Review and customize** task files as needed

### Equivalent commands:
```bash
# Old way
ansible-playbook -i inventory.ini playbook.yml

# New way
ansible-playbook -i inventory.ini playbook-refactored.yml
```

Both produce the same result, but the new way is more maintainable.

## Customization

### Modify Docker Compose services:
Edit `templates/docker-compose.yml.j2`

### Change Traefik configuration:
Edit `templates/traefik.toml.j2`

### Update Matrix settings:
Edit `tasks/matrix.yml`

### Add new service:
1. Create configuration in `tasks/service-configs.yml`
2. Add to `templates/docker-compose.yml.j2`
3. Update `tasks/services.yml` if health checks needed

## Environment Variables Required

See the main playbook for required environment variables:
- `DOMAIN_NAME`
- `EMAIL_ADDRESS`
- `MATRIX_ADMIN_PASSWORD`
- `MATRIX_POSTGRES_PASSWORD`
- `MATRIX_REGISTRATION_SECRET`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `TURN_SHARED_SECRET`
- `JITSI_ADMIN_USER`
- `JITSI_ADMIN_PASSWORD`
- `STORAGEBOX_HOST` (optional, for backups)
- `STORAGEBOX_USER` (optional)
- `STORAGEBOX_PASSWORD` (optional)

## Troubleshooting

### Task fails in middle of playbook:
Use tags to resume from that point:
```bash
ansible-playbook -i inventory.ini playbook-refactored.yml --start-at-task="Task Name"
```

### Want to see what will run:
```bash
ansible-playbook -i inventory.ini playbook-refactored.yml --list-tasks
ansible-playbook -i inventory.ini playbook-refactored.yml --list-tags
```

### Run in check mode (dry run):
```bash
ansible-playbook -i inventory.ini playbook-refactored.yml --check
```

## Contributing

When adding new features:
1. Create or update appropriate task file in `tasks/`
2. Add templates to `templates/` if needed
3. Update this README with new tags/features
4. Test thoroughly before committing
