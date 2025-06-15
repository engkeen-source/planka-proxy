#!/bin/bash

echo "🔄 Restarting both Planka and Proxy stacks..."

# Stop proxy first
echo "🛑 Stopping proxy stack..."
cd /Users/engkeentan/Development/CEO_Dashboard/proxy
docker-compose down

# Stop planka
echo "🛑 Stopping planka stack..."
cd /Users/engkeentan/Development/CEO_Dashboard/planka
docker-compose down

echo "⏳ Waiting for containers to stop..."
sleep 5

# Start planka first (to create the network)
echo "🚀 Starting planka stack..."
cd /Users/engkeentan/Development/CEO_Dashboard/planka
docker-compose up -d

echo "⏳ Waiting for planka to be ready..."
sleep 10

# Start proxy (connects to planka's network)
echo "🚀 Starting proxy stack..."
cd /Users/engkeentan/Development/CEO_Dashboard/proxy
docker-compose up -d

echo "⏳ Waiting for proxy to be ready..."
sleep 10

echo "✅ Both stacks restarted!"
echo ""
echo "🔍 Container status:"
docker ps | grep planka

echo ""
echo "🔗 Testing network connectivity..."
echo "Testing if proxy can reach planka..."
docker exec planka-proxy-server curl -s http://planka:1337 > /dev/null && echo "✅ Proxy → Planka: Connected" || echo "❌ Proxy → Planka: Failed"

echo ""
echo "🌐 Test URLs:"
echo "  Frontend iframe: http://localhost/planka-login?email=test@example.com"
echo "  Direct planka: http://localhost:4000"
echo "  Nginx health: http://localhost/health" 