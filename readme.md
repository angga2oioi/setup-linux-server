# nginx-proxy-setup

> Stop remembering nginx configs. One curl command to set up a reverse proxy with SSL.

Interactive script to automatically configure nginx as a reverse proxy with optional Let's Encrypt SSL certificates.

## Features

✨ **One-Command Setup** - Install and configure everything with a single command  
🔒 **Automatic SSL** - Optional Let's Encrypt certificate installation  
🎯 **Interactive** - Prompts guide you through the entire process  
🛡️ **Safe** - Checks existing configs and asks before overwriting  
📦 **Smart Installation** - Only installs what you need  
⚡ **Production Ready** - Includes proper headers for WebSocket, real IP, and more

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-nginx-proxy/main/setup.sh | sudo bash
```

That's it! The script will guide you through the rest.

## What It Does

1. **Checks for nginx** - Installs if missing (with your permission)
2. **Checks for certbot** - Installs if missing (with your permission)
3. **Asks for domain** - e.g., `api.example.com`
4. **Checks existing config** - Won't overwrite without asking
5. **Asks for backend** - IP and port of your application
6. **Generates config** - Creates optimized nginx reverse proxy config
7. **Enables site** - Activates and reloads nginx
8. **Optional SSL** - Sets up Let's Encrypt certificate if you want

## Requirements

- Ubuntu/Debian-based system (uses `apt-get`)
- Root access (script will check)
- Port 80 and 443 accessible (for SSL)
- DNS pointing to your server (for SSL)

## Usage Example

```bash
$ curl -fsSL https://raw.githubusercontent.com/angga2oioi/nginx-proxy-setup/main/setup.sh | sudo bash

ℹ Nginx Reverse Proxy Setup Script

ℹ Checking for nginx...
✓ Nginx is already installed

ℹ Checking for certbot...
✓ Certbot is already installed

ℹ Enter the domain name for the reverse proxy:
Domain (e.g., api.example.com): api.mysite.com

ℹ No existing configuration found. Creating new one...

ℹ Enter the backend server details:
IP address (e.g., 127.0.0.1): 127.0.0.1
Port (e.g., 3000): 3000

ℹ Creating nginx configuration for api.mysite.com -> 127.0.0.1:3000
✓ Configuration file created

ℹ Enabling site...
✓ Site enabled

ℹ Testing nginx configuration...
✓ Nginx configuration is valid
ℹ Reloading nginx...
✓ Nginx reloaded

Do you want to setup SSL with Let's Encrypt for api.mysite.com? [y/n]: y
⚠ Make sure:
⚠   1. DNS is pointing to this server
⚠   2. Port 80 and 443 are open

Enter your email address for Let's Encrypt: you@example.com
ℹ Running certbot...
✓ SSL certificate installed successfully!

✓ ✨ Setup complete!
```

## Generated Config

The script creates an optimized nginx configuration with:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

When SSL is enabled, certbot automatically upgrades this to HTTPS.

## Manual Installation

If you prefer to inspect the script first:

```bash
# Download
curl -fsSL https://raw.githubusercontent.com/angga2oioi/nginx-proxy-setup/main/setup.sh -o setup.sh

# Inspect
cat setup.sh

# Make executable
chmod +x setup.sh

# Run
sudo ./setup.sh
```

## Common Use Cases

### Node.js App
```
Domain: api.example.com
IP: 127.0.0.1
Port: 3000
```

### Python/Flask App
```
Domain: app.example.com
IP: 127.0.0.1
Port: 5000
```

### Docker Container
```
Domain: service.example.com
IP: 172.17.0.2 (or 127.0.0.1 if port mapped)
Port: 8080
```

### Another Server
```
Domain: proxy.example.com
IP: 192.168.1.100
Port: 80
```

## Useful Commands

After setup, you might need these:

```bash
# View nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Edit your config
sudo nano /etc/nginx/sites-available/your-domain.com

# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Renew SSL (automatic, but can force)
sudo certbot renew --dry-run
```

## Troubleshooting

### SSL Certificate Fails

Make sure:
- DNS A record points to your server's IP
- Port 80 and 443 are open in firewall
- No other service is using port 80/443
- Domain is accessible from the internet

### Connection Refused

Check if your backend is running:
```bash
curl http://127.0.0.1:3000  # Replace with your IP:port
```

### 502 Bad Gateway

Your backend might be down or not listening on the specified port:
```bash
sudo systemctl status your-app
netstat -tulpn | grep :3000  # Check if port is listening
```

## Security Notes

- The script requires root access to install packages and modify nginx configs
- Review the script before running if security is a concern
- SSL certificates from Let's Encrypt are free and renew automatically
- The script doesn't modify firewall rules - ensure ports 80/443 are open

## Contributing

Issues and pull requests are welcome! Some ideas for contributions:

- [ ] Support for other package managers (yum, pacman)
- [ ] Multiple backend support (load balancing)
- [ ] Custom SSL certificate support
- [ ] Automatic firewall configuration
- [ ] Docker deployment option
- [ ] Rate limiting options
- [ ] Basic auth setup

## License

MIT License - feel free to use this however you want!

## Author

Created because I got tired of Googling "nginx reverse proxy config" for every project.

---

**Star this repo** if it saved you time! ⭐