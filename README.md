# Dockerized Nginx Reverse Proxy

A dockerized nginx reverse proxy setup that listens on custom ports:
- **HTTP**: Port 5080
- **HTTPS**: Port 5443

## Quick Start

1. **Run the setup script** to generate SSL certificates:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Start the proxy with test backend**:
   ```bash
   docker-compose up -d
   ```

3. **Test the setup**:
   - HTTP: http://localhost:5080
   - HTTPS: https://localhost:5443 (accept SSL warning)
   - Health check: http://localhost:5080/health

4. **Replace with your backend** (see Configuration section below)

## What's Included

The setup includes a test backend service to verify everything works. Once confirmed, you can replace it with your actual backend services.

### Files Structure
```
.
├── docker-compose.yml      # Docker services configuration
├── nginx.conf             # Nginx reverse proxy configuration  
├── test-backend.html      # Test backend page
├── ssl/                   # SSL certificates directory
│   ├── cert.pem          # SSL certificate
│   └── key.pem           # SSL private key
├── setup.sh              # Setup script
└── README.md             # This file
```

## 🌐 **Subdomain Routing**

The proxy now supports subdomain-based routing:

- **`localhost:5080`** → Main website  
- **`reposlite.localhost:5080`** → Routes to localhost:9156

See `subdomain-setup.md` for detailed configuration instructions.

### Quick Subdomain Setup:
1. Add to `/etc/hosts`: `127.0.0.1 reposlite.localhost`
2. Start your service on localhost:9156
3. Test: `curl http://reposlite.localhost:5080`

## Configuration

## Configuration

### Using Your Own Backend

The default setup includes a test backend. To use your own services:

1. **Option A: Replace the test backend in docker-compose.yml**
   ```yaml
   # Replace the test-backend service with your app
   your-app:
     image: your-app:latest
     networks:
       - proxy-network
   ```

2. **Option B: Remove test backend and use external services**
   ```yaml
   # Remove the test-backend service entirely
   # Update nginx.conf to point to external services
   ```

3. **Update nginx.conf upstream section**:
   ```nginx
   upstream backend {
       server your-app:3000;        # Docker service
       server 172.17.0.1:8080;      # Host machine service
       server external-api:443;     # External service
   }
   ```

### Backend Server Examples

**Docker services in the same compose file:**
```nginx
upstream backend {
    server web-app:3000;
    server api-server:8080;
}
```

**Host machine services:**
```nginx
upstream backend {
    server 172.17.0.1:3000;  # Linux host
    server host.docker.internal:3000;  # Docker Desktop
}
```

**External services:**
```nginx
upstream backend {
    server api.example.com:443;
    server backup-api.example.com:443;
}
```

### Load Balancing

Add multiple servers for load balancing:

```nginx
upstream backend {
    server app1:3000 weight=3;
    server app2:3000 weight=2;
    server app3:3000 backup;  # Backup server
}
```

### SSL Certificates

For production, replace the self-signed certificates:

1. **Let's Encrypt** (recommended):
   ```bash
   # Place your certificates in the ssl/ directory
   cp /path/to/fullchain.pem ssl/cert.pem
   cp /path/to/privkey.pem ssl/key.pem
   ```

2. **Custom certificates**:
   - Replace `ssl/cert.pem` with your certificate
   - Replace `ssl/key.pem` with your private key

### Domain Configuration

Update server names in `nginx.conf`:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    # ...
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    # ...
}
```

## Advanced Features

### Multiple Upstreams

Configure different backends for different paths:

```nginx
upstream api_backend {
    server api-server:3000;
}

upstream web_backend {
    server web-server:8080;
}

server {
    # ...
    location /api/ {
        proxy_pass http://api_backend;
        # proxy headers...
    }
    
    location / {
        proxy_pass http://web_backend;
        # proxy headers...
    }
}
```

### Health Checks

The configuration includes a health check endpoint at `/health`. Access it at:
- http://localhost:5080/health
- https://localhost:5443/health

### WebSocket Support

WebSocket connections are supported by default with the included proxy headers.

## Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f nginx-proxy

# Reload nginx configuration
docker-compose exec nginx-proxy nginx -s reload

# Stop services
docker-compose down

# Restart with new configuration
docker-compose restart nginx-proxy
```

## Troubleshooting

### Common Issues

1. **Connection refused**: Check if backend servers are running and accessible
2. **SSL errors with self-signed cert**: Browser will show warnings - accept the risk for development
3. **502 Bad Gateway**: Backend server is not responding or unreachable

### Debugging

```bash
# Check nginx configuration syntax
docker-compose exec nginx-proxy nginx -t

# View nginx error logs
docker-compose logs nginx-proxy

# Test backend connectivity from container
docker-compose exec nginx-proxy wget -qO- http://your-backend:port
```

### Port Conflicts

If ports 5080 or 5443 are in use, update the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "6080:80"   # Change external port
  - "6443:443"  # Change external port
```

## Security Notes

- The self-signed certificate is for development only
- Use proper SSL certificates in production
- Consider adding rate limiting and security headers
- Keep nginx updated by pulling the latest image regularly
