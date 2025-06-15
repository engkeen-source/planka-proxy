#!/bin/bash

# Script called when Let's Encrypt certificates are renewed
# This updates the certificates in Docker and restarts nginx

set -e

DOMAIN="planka.zackywacky.net"
SSL_DIR="./nginx/ssl"

echo "🔄 Renewing SSL certificates for $DOMAIN..."

# Copy renewed certificates
sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"

# Fix permissions
sudo chown $USER:$USER "$SSL_DIR/cert.pem" "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"
chmod 600 "$SSL_DIR/key.pem"

# Restart nginx container to load new certificates
docker-compose restart nginx

echo "✅ SSL certificates renewed and nginx restarted!" 