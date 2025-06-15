#!/bin/bash

# Script to generate self-signed SSL certificates for development
# For production, replace these with proper certificates from a CA

set -e

SSL_DIR="./nginx/ssl"
CERT_FILE="$SSL_DIR/cert.pem"
KEY_FILE="$SSL_DIR/key.pem"

echo "🔐 Generating SSL certificates for nginx..."

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate private key
echo "Generating private key..."
openssl genrsa -out "$KEY_FILE" 2048

# Generate certificate signing request
echo "Generating certificate..."
openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days 365 -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost"

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo "✅ SSL certificates generated successfully!"
echo "📁 Certificate: $CERT_FILE"
echo "🔑 Private key: $KEY_FILE"
echo ""
echo "⚠️  WARNING: These are self-signed certificates for development only!"
echo "⚠️  For production, use certificates from a trusted Certificate Authority."
echo ""
echo "🚀 You can now run: docker-compose up -d" 