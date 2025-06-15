#!/bin/bash

# Script to set up Let's Encrypt SSL certificates for planka.zackywacky.net
# This replaces the self-signed certificates with real ones

set -e

DOMAIN="planka.zackywacky.net"
EMAIL="tanengkeen@gmail.com"  # Replace with your email
SSL_DIR="./nginx/ssl"

echo "🔐 Setting up Let's Encrypt SSL for $DOMAIN..."

# Install certbot if not already installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Stop nginx to free up port 80 for certificate generation
echo "🛑 Stopping nginx services..."
sudo systemctl stop nginx 2>/dev/null || true
docker-compose down 2>/dev/null || true

# Generate Let's Encrypt certificate
echo "🔒 Generating Let's Encrypt certificate for $DOMAIN..."
sudo certbot certonly \
    --standalone \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --domains "$DOMAIN"

# Create SSL directory
mkdir -p "$SSL_DIR"

# Copy certificates to our nginx directory
echo "📋 Copying certificates..."
sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"

# Fix permissions
sudo chown $USER:$USER "$SSL_DIR/cert.pem" "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"
chmod 600 "$SSL_DIR/key.pem"

echo "✅ Let's Encrypt certificates installed successfully!"
echo "📁 Certificate: $SSL_DIR/cert.pem"
echo "🔑 Private key: $SSL_DIR/key.pem"
echo ""
echo "🔄 Setting up auto-renewal..."

# Set up auto-renewal cron job
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'cd $(pwd) && ./renew-ssl.sh'") | crontab -

echo "✅ Auto-renewal set up! Certificates will renew automatically."
echo ""
echo "🚀 You can now run: docker-compose up -d" 