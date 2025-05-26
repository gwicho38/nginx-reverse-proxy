# Subdomain Routing Setup Guide

Your nginx reverse proxy now supports subdomain-based routing! Here's how to set it up and use it.

## 🌐 **Routing Configuration**

### Current Routes:
- **`localhost:5080`** → Main website (test-backend)
- **`reposlite.localhost:5080`** → Reposlite service (localhost:9156)

### HTTPS Routes:
- **`localhost:5443`** → Main website (HTTPS)
- **`reposlite.localhost:5443`** → Reposlite service (HTTPS)

## 🔧 **Setup Steps**

### 1. Update Your Configuration
The nginx configuration has been updated with separate server blocks for each subdomain.

### 2. Restart the Proxy
```bash
docker compose restart nginx-proxy
```

### 3. Configure Local DNS (Required)
Since we're using `.localhost` subdomains, you need to add entries to your `/etc/hosts` file:

**On Linux/macOS:**
```bash
# Add these lines to /etc/hosts
sudo echo "127.0.0.1 reposlite.localhost" >> /etc/hosts
```

**On Windows:**
Edit `C:\Windows\System32\drivers\etc\hosts` and add:
```
127.0.0.1 reposlite.localhost
```

### 4. Start Your Reposlite Service
Make sure your Reposlite service is running on `localhost:9156`:
```bash
# Example: if using Docker
docker run -d -p 9156:8080 dzikoysk/reposilite

# Or if running directly
java -jar reposilite.jar --port=9156
```

## 🧪 **Testing**

### Test the Routes:
```bash
# Main site
curl http://localhost:5080
curl -k https://localhost:5443

# Reposlite subdomain  
curl http://reposlite.localhost:5080
curl -k https://reposlite.localhost:5443

# Health checks
curl http://localhost:5080/health
curl http://reposlite.localhost:5080/health
```

### Run the Test Script:
```bash
./test-proxy.sh
```

## 📝 **Adding More Subdomains**

To add more subdomains, follow this pattern in `nginx.conf`:

### 1. Add Upstream
```nginx
upstream myservice_backend {
    server host.docker.internal:8080;  # Your service port
}
```

### 2. Add HTTP Server Block
```nginx
server {
    listen 80;
    server_name myservice.localhost;
    
    location / {
        proxy_pass http://myservice_backend;
        # ... proxy headers (copy from existing blocks)
    }
}
```

### 3. Add HTTPS Server Block
```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name myservice.localhost;
    
    # SSL config (copy from existing blocks)
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    location / {
        proxy_pass http://myservice_backend;
        # ... proxy headers (copy from existing blocks)
    }
}
```

### 4. Update /etc/hosts
```bash
sudo echo "127.0.0.1 myservice.localhost" >> /etc/hosts
```

## 🔍 **Troubleshooting**

### Common Issues:

**1. "502 Bad Gateway"**
- Your backend service (e.g., Reposlite on port 9156) isn't running
- Check if the service is accessible: `curl http://localhost:9156`

**2. "Cannot resolve subdomain"**
- You haven't added the subdomain to `/etc/hosts`
- DNS cache issue: try `sudo systemctl flush-dns` (Linux) or restart browser

**3. "Connection refused"**
- nginx can't reach the backend service
- Check if `host.docker.internal` works: `docker compose exec nginx-proxy ping host.docker.internal`
- On Linux, you might need to use `172.17.0.1` instead

### Docker Network Issues:
If `host.docker.internal` doesn't work on Linux, update the upstream in `nginx.conf`:

```nginx
upstream reposlite_backend {
    server 172.17.0.1:9156;  # Linux Docker bridge IP
}
```

### Check Container Logs:
```bash
docker compose logs nginx-proxy
docker compose logs test-backend
```

## 🚀 **Production Considerations**

### Real Domain Names
For production, replace `.localhost` with your actual domain:

```nginx
server_name api.yourdomain.com;
server_name admin.yourdomain.com;
```

### SSL Certificates
Use proper SSL certificates for each subdomain:
- Let's Encrypt with certbot
- Wildcard certificates for `*.yourdomain.com`

### Example Certbot Setup:
```bash
certbot --nginx -d yourdomain.com -d api.yourdomain.com -d admin.yourdomain.com
```

## 🎯 **Example Services**

Here are some common services you might want to route:

- **`api.localhost:5080`** → API server (port 3000)
- **`admin.localhost:5080`** → Admin panel (port 8080)  
- **`docs.localhost:5080`** → Documentation site (port 4000)
- **`grafana.localhost:5080`** → Grafana dashboard (port 3000)
- **`jenkins.localhost:5080`** → Jenkins CI/CD (port 8080)

Each just needs its own upstream and server block configuration!
