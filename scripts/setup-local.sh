#!/bin/bash
# Quick setup script for RouteMaker local development on Fedora

set -e

echo "🚀 Setting up RouteMaker local development environment..."
echo ""

# Check what's already installed
echo "Checking installed tools..."
HAS_NODE=false
HAS_COMPOSE=false

if command -v node &> /dev/null; then
    echo "✓ Node.js $(node --version) is installed"
    HAS_NODE=true
else
    echo "✗ Node.js is not installed"
fi

if command -v podman-compose &> /dev/null || command -v docker-compose &> /dev/null; then
    echo "✓ Compose tool is installed"
    HAS_COMPOSE=true
else
    echo "✗ Compose tool is not installed"
fi

echo ""
echo "Choose installation method:"
echo "  1) Docker/Podman (recommended - isolated environment)"
echo "  2) Direct Node.js (faster, local development)"
echo ""
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo "📦 Installing podman-compose..."
    sudo dnf install -y podman-compose
    
    echo ""
    echo "✅ Dependencies installed!"
    echo ""
    echo "Starting RouteMaker with Podman..."
    cd routemaker
    podman-compose -f ../docker-compose.local.yml up --build -d
    
    echo ""
    echo "🎉 RouteMaker is starting!"
    echo "   Access at: http://localhost:3000"
    echo ""
    echo "Create a user with:"
    echo "   podman exec -it routemaker-local node manage-users.js create"
    
elif [ "$choice" = "2" ]; then
    echo ""
    echo "📦 Installing Node.js..."
    sudo dnf install -y nodejs npm
    
    echo ""
    echo "📦 Installing RouteMaker dependencies..."
    cd routemaker
    npm install
    
    echo ""
    echo "✅ Dependencies installed!"
    echo ""
    echo "Starting RouteMaker..."
    mkdir -p data
    npm start &
    APP_PID=$!
    
    echo ""
    echo "🎉 RouteMaker is running! (PID: $APP_PID)"
    echo "   Access at: http://localhost:3000"
    echo ""
    echo "Create a user in a new terminal:"
    echo "   cd routemaker && node manage-users.js create"
    echo ""
    echo "To stop: kill $APP_PID"
    
else
    echo "Invalid choice"
    exit 1
fi
