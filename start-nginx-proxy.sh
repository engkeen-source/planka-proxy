#!/bin/bash

# Quick start script for nginx reverse proxy setup
# This script automates the entire setup process

set -e

echo "🚀 Starting Nginx Reverse Proxy Setup for Planka Proxy"
echo "=================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ Docker Compose is not installed. Please install it and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Please create one with your configuration:"
    echo "   PLANKA_URL=https://your-planka-instance.com"
    echo "   PLANKA_DEFAULT_USER_PASSWORD=your-password"
    echo ""
    read -p "Do you want to continue with default values? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please create a .env file and run this script again."
        exit 1
    fi
fi

# Generate SSL certificates if they don't exist
if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
    echo "🔐 SSL certificates not found. Generating self-signed certificates..."
    chmod +x generate-ssl.sh
    ./generate-ssl.sh
else
    echo "✅ SSL certificates found."
fi

# Stop any running containers
echo "🛑 Stopping any existing containers..."
docker-compose down > /dev/null 2>&1 || true

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep "Up" > /dev/null; then
    echo "✅ Services are running successfully!"
    echo ""
    echo "🌐 Your nginx reverse proxy is now available at:"
    echo "   HTTP (redirects to HTTPS): http://localhost"
    echo "   HTTPS: https://localhost"
    echo "   Health check: https://localhost/health"
    echo ""
    echo "🔑 Login URL example:"
    echo "   https://localhost/planka-login?email=user@example.com"
    echo ""
    echo "📊 To view logs:"
    echo "   docker-compose logs -f"
    echo ""
    echo "🛑 To stop services:"
    echo "   docker-compose down"
    echo ""
    echo "⚠️  Note: You're using self-signed certificates. Your browser will show a security warning."
    echo "   For production, replace the certificates in nginx/ssl/ with proper CA-issued certificates."
else
    echo "❌ Some services failed to start. Check the logs:"
    docker-compose logs
    exit 1
fi 