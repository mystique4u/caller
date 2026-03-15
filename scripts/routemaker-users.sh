#!/bin/bash

# RouteMaker User Management Script
# Allows easy management of RouteMaker users

set -e

CONTAINER_NAME="routemaker"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: RouteMaker container is not running${NC}"
    echo "Please deploy the services first using Ansible"
    exit 1
fi

# Function to display usage
usage() {
    echo "RouteMaker User Management"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  create    Create a new user"
    echo "  list      List all users"
    echo "  delete    Delete a user"
    echo ""
    echo "Examples:"
    echo "  $0 create"
    echo "  $0 list"
    echo "  $0 delete"
    exit 1
}

# Main script
if [ $# -eq 0 ]; then
    usage
fi

COMMAND=$1

case $COMMAND in
    create)
        echo -e "${GREEN}Creating a new RouteMaker user${NC}"
        docker exec -it ${CONTAINER_NAME} node manage-users.js create
        ;;
    
    list)
        echo -e "${GREEN}Listing RouteMaker users${NC}"
        docker exec -it ${CONTAINER_NAME} node manage-users.js list
        ;;
    
    delete)
        echo -e "${YELLOW}Deleting a RouteMaker user${NC}"
        docker exec -it ${CONTAINER_NAME} node manage-users.js delete
        ;;
    
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        usage
        ;;
esac
