#!/bin/bash

# RouteMaker Local Development Helper Script

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

COMPOSE_FILE="docker-compose.local.yml"

show_usage() {
    echo -e "${BLUE}RouteMaker Local Development${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start         Start the application"
    echo "  stop          Stop the application"
    echo "  restart       Restart the application"
    echo "  logs          Show application logs"
    echo "  build         Rebuild the application"
    echo "  user-create   Create a new user"
    echo "  user-list     List all users"
    echo "  user-delete   Delete a user"
    echo "  reset         Reset database (delete all data)"
    echo "  shell         Open shell in container"
    echo "  clean         Stop and remove all data"
    echo ""
    exit 1
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed${NC}"
        exit 1
    fi
}

get_compose_cmd() {
    if docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

start_app() {
    echo -e "${GREEN}Starting RouteMaker...${NC}"
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $COMPOSE_FILE up -d --build
    echo ""
    echo -e "${GREEN}✓ RouteMaker is running!${NC}"
    echo -e "  Access at: ${BLUE}http://localhost:3000${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Create a user: ${YELLOW}$0 user-create${NC}"
    echo -e "  2. Open http://localhost:3000 in your browser"
    echo -e "  3. View logs: ${YELLOW}$0 logs${NC}"
}

stop_app() {
    echo -e "${YELLOW}Stopping RouteMaker...${NC}"
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $COMPOSE_FILE stop
    echo -e "${GREEN}✓ Stopped${NC}"
}

restart_app() {
    echo -e "${YELLOW}Restarting RouteMaker...${NC}"
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $COMPOSE_FILE restart
    echo -e "${GREEN}✓ Restarted${NC}"
}

show_logs() {
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $COMPOSE_FILE logs -f
}

build_app() {
    echo -e "${YELLOW}Rebuilding RouteMaker...${NC}"
    COMPOSE_CMD=$(get_compose_cmd)
    $COMPOSE_CMD -f $COMPOSE_FILE build --no-cache
    echo -e "${GREEN}✓ Build complete${NC}"
}

create_user() {
    echo -e "${GREEN}Creating a new user${NC}"
    docker exec -it routemaker-local node manage-users.js create
}

list_users() {
    echo -e "${GREEN}Users:${NC}"
    docker exec -it routemaker-local node manage-users.js list
}

delete_user() {
    echo -e "${YELLOW}Delete a user${NC}"
    docker exec -it routemaker-local node manage-users.js delete
}

reset_db() {
    echo -e "${RED}⚠️  This will delete all routes and users!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Stopping application...${NC}"
        COMPOSE_CMD=$(get_compose_cmd)
        $COMPOSE_CMD -f $COMPOSE_FILE stop
        
        echo -e "${YELLOW}Removing database...${NC}"
        rm -rf ./routemaker/data/*.db ./routemaker/data/*.db-journal
        
        echo -e "${GREEN}Starting application...${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE start
        
        echo -e "${GREEN}✓ Database reset complete${NC}"
        echo "Create a new user with: $0 user-create"
    else
        echo "Cancelled"
    fi
}

open_shell() {
    echo -e "${BLUE}Opening shell in container...${NC}"
    docker exec -it routemaker-local sh
}

clean_all() {
    echo -e "${RED}⚠️  This will remove all containers and data!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        COMPOSE_CMD=$(get_compose_cmd)
        $COMPOSE_CMD -f $COMPOSE_FILE down -v
        rm -rf ./routemaker/data/*.db ./routemaker/data/*.db-journal
        echo -e "${GREEN}✓ Cleaned${NC}"
    else
        echo "Cancelled"
    fi
}

# Main script
check_docker

if [ $# -eq 0 ]; then
    show_usage
fi

COMMAND=$1

case $COMMAND in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    logs)
        show_logs
        ;;
    build)
        build_app
        ;;
    user-create)
        create_user
        ;;
    user-list)
        list_users
        ;;
    user-delete)
        delete_user
        ;;
    reset)
        reset_db
        ;;
    shell)
        open_shell
        ;;
    clean)
        clean_all
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        ;;
esac
