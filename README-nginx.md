# Nginx Reverse Proxy Setup for Planka Proxy

This setup adds an nginx reverse proxy layer in front of your existing Express.js proxy server, providing enhanced security, performance, and scalability.

## 🏗️ Architecture

```
Internet → Nginx (Port 80/443) → Your Proxy Server (Port 3001) → Planka
```

## ✨ Benefits

- **SSL Termination**: Handle HTTPS at the nginx level
- **Rate Limiting**: Protect against abuse and DDoS attacks
- **Security Headers**: Add security headers automatically
- **Static File Caching**: Improve performance for static assets
- **WebSocket Support**: Full support for real-time connections
- **Load Balancing**: Ready for scaling multiple proxy instances
- **Better Logging**: Structured access and error logs

## 📁 File Structure

```
proxy/
├── nginx/
│   ├── nginx.conf          # Main nginx configuration
│   └── ssl/               # SSL certificates directory
├── docker-compose.yml      # Container orchestration
├── Dockerfile             # Proxy server container
├── generate-ssl.sh        # SSL certificate generator
├── proxy-server.js        # Your existing proxy server
└── README-nginx.md        # This documentation
```

## 🚀 Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- OpenSSL (for generating SSL certificates)
- Your existing proxy server working

### 2. Generate SSL Certificates

For development (self-signed certificates):
```bash
chmod +x generate-ssl.sh
./generate-ssl.sh
```

For production, replace the generated certificates with proper ones from a CA:
```bash
# Copy your production certificates
cp your-cert.pem nginx/ssl/cert.pem
cp your-key.pem nginx/ssl/key.pem
```

### 3. Configure Environment Variables

Create a `.env` file in the proxy directory:
```bash
# Copy from your existing environment or create new
PLANKA_URL=https://your-planka-instance.com
PLANKA_DEFAULT_USER_PASSWORD=your-default-password
PROXY_PORT=3001
NODE_ENV=production
```

### 4. Start the Services

```bash
# Start both nginx and your proxy server
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 5. Test the Setup

- HTTP (will redirect to HTTPS): http://localhost
- HTTPS: https://localhost
- Health check: https://localhost/health
- Login: https://localhost/planka-login?email=user@example.com

## ⚙️ Configuration

### Rate Limiting

The nginx configuration includes three rate limiting zones:

- **Login endpoints** (`/planka-login`, `/proxy-auth-login`): 5 requests/minute
- **API endpoints** (`/api/*`): 30 requests/minute  
- **General requests**: 100 requests/minute

Modify these in `nginx/nginx.conf`:
```nginx
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/m;
limit_req_zone $binary_remote_addr zone=general:10m rate=100r/m;
```

### Security Headers

The following security headers are automatically added:
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (HSTS)
- `Content-Security-Policy`
- `Referrer-Policy`

### SSL Configuration

Modern SSL/TLS configuration with:
- TLS 1.2 and 1.3 support
- Strong cipher suites
- HSTS enabled
- Session caching

## 🔧 Customization

### Adding Custom Domains

1. Update the `server_name` in `nginx/nginx.conf`:
```nginx
server_name your-domain.com www.your-domain.com;
```

2. Update your DNS records to point to your server
3. Get proper SSL certificates for your domain

### Load Balancing

To add multiple proxy server instances:

1. Update `docker-compose.yml`:
```yaml
proxy-server-1:
  # ... existing config
proxy-server-2:
  # ... existing config
```

2. Update the upstream in `nginx/nginx.conf`:
```nginx
upstream proxy_backend {
    server proxy-server-1:3001;
    server proxy-server-2:3001;
    keepalive 32;
}
```

### Custom Nginx Configuration

Create additional configuration files in `nginx/sites-available/` and symlink them to `nginx/sites-enabled/` for complex setups.

## 📊 Monitoring

### Health Checks

- Nginx health: `https://your-domain/health`
- Proxy server health: Built into Docker Compose
- Container status: `docker-compose ps`

### Logs

View logs in real-time:
```bash
# All services
docker-compose logs -f

# Nginx only
docker-compose logs -f nginx

# Proxy server only
docker-compose logs -f proxy-server
```

Log files are stored in:
- Nginx logs: Docker volume `nginx_logs`
- Proxy logs: `./logs/` directory

### Log Rotation

The setup includes automatic log rotation:
- Nginx logs: Rotated daily, kept for 52 days
- Application logs: Rotated daily, kept for 30 days

## 🚨 Troubleshooting

### Common Issues

1. **Port 80/443 already in use**
```bash
# Check what's using the ports
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services or change ports in docker-compose.yml
```

2. **SSL certificate errors**
```bash
# Regenerate certificates
./generate-ssl.sh

# Check certificate validity
openssl x509 -in nginx/ssl/cert.pem -text -noout
```

3. **Proxy server not starting**
```bash
# Check proxy server logs
docker-compose logs proxy-server

# Verify environment variables
docker-compose config
```

4. **Rate limiting too aggressive**
   - Adjust rates in `nginx/nginx.conf`
   - Restart nginx: `docker-compose restart nginx`

### Debug Mode

Enable debug logging in `nginx/nginx.conf`:
```nginx
error_log /var/log/nginx/error.log debug;
```

Then restart:
```bash
docker-compose restart nginx
```

## 🔒 Security Best Practices

1. **Use proper SSL certificates** in production
2. **Regularly update** container images
3. **Monitor logs** for suspicious activity
4. **Adjust rate limits** based on your needs
5. **Use strong passwords** for Planka
6. **Keep nginx updated** for security patches

## 🚀 Production Deployment

### Before Going Live

1. Replace self-signed certificates with proper CA-issued certificates
2. Configure proper domain names in nginx
3. Set up monitoring and alerting
4. Configure log aggregation
5. Set up automated backups
6. Review and adjust security settings

### Environment Variables for Production

```bash
NODE_ENV=production
PROXY_PORT=3001
PLANKA_URL=https://your-planka-domain.com
PLANKA_DEFAULT_USER_PASSWORD=strong-password-here
```

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SSL/TLS Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [Rate Limiting with Nginx](https://www.nginx.com/blog/rate-limiting-nginx/)

## 🤝 Support

If you encounter issues:
1. Check the logs first: `docker-compose logs -f`
2. Verify your configuration files
3. Test with curl or browser developer tools
4. Check firewall and DNS settings

---

**Note**: This setup is designed to work with your existing Planka proxy server. The nginx layer adds security and performance benefits while maintaining compatibility with your current authentication flow. 