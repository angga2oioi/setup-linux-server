# setup-linux-server

> Stop remembering server configs. Two curl commands to harden your server and set up reverse proxies with SSL.

Interactive scripts to automatically harden your server and configure nginx as a reverse proxy with optional Let's Encrypt SSL certificates.

## Features

### 🛡️ Server Hardening (`harden-server.sh`)
💾 **Swap Configuration** - Set up swap with custom size  
🔥 **Firewall (UFW)** - Configure rules for SSH, HTTP, HTTPS, and custom ports  
🚫 **Fail2Ban** - Protect against brute force attacks  
🔐 **SSH Hardening** - Disable root login, password auth, change port  
🔄 **Auto Updates** - Enable automatic security updates  
⚡ **Performance Tuning** - Increase file descriptors and system limits  
🌍 **Timezone Setup** - Configure server timezone  
👤 **User Management** - Create non-root sudo user with SSH keys  

### 🔄 Nginx Reverse Proxy (`setup-proxy.sh`)
✨ **One-Command Setup** - Install and configure everything with a single command  
🔒 **Automatic SSL** - Optional Let's Encrypt certificate installation  
🎯 **Interactive** - Prompts guide you through the entire process  
🛡️ **Safe** - Checks existing configs and asks before overwriting  
📦 **Smart Installation** - Only installs what you need  
⚡ **Production Ready** - Includes proper headers for WebSocket, real IP, and more

## Quick Start

### New Server Setup (Recommended)

Run both scripts to harden your server and set up a reverse proxy:

```bash
# 1. Harden your server first
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/harden-server.sh | sudo bash

# 2. Set up reverse proxy
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/setup-proxy.sh | sudo bash
```

### Just Need Reverse Proxy?

```bash
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/setup-proxy.sh | sudo bash
```

### Just Need Hardening?

```bash
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/harden-server.sh | sudo bash
```

That's it! The scripts will guide you through the rest.

## What It Does

### Server Hardening Script

1. **Swap Configuration** - Creates or reconfigures swap with your chosen size
2. **Firewall Setup** - Configures UFW with sensible defaults (SSH, HTTP, HTTPS)
3. **Fail2Ban** - Installs and configures protection against brute force
4. **SSH Hardening** - Multiple security improvements:
   - Disable root login
   - Disable password authentication (SSH keys only)
   - Change default SSH port
   - Limit authentication attempts
   - Connection timeouts
5. **Auto Security Updates** - Enables unattended-upgrades
6. **System Limits** - Increases file descriptors and connection limits
7. **Timezone** - Sets proper timezone for logs
8. **User Creation** - Creates non-root sudo user with SSH key setup

### Reverse Proxy Script

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

## Usage Examples

### Hardening a Fresh Server

```bash
$ curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/harden-server.sh | sudo bash

🛡️  Server Hardening Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💾 Swap Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠ No swap found
Do you want to create swap? [y/n]: y
ℹ Enter swap size in GB (recommended: 2-4 for small VPS):
Swap size (GB): 2
ℹ Creating 2GB swap file...
✓ Swap created: 2GB

🔥 Firewall Configuration (UFW)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ UFW is already installed
Do you want to configure firewall rules? [y/n]: y
⚠ Default rules will be:
⚠   - Allow SSH (port 22)
⚠   - Allow HTTP (port 80)
⚠   - Allow HTTPS (port 443)
...

🔐 SSH Hardening
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Do you want to harden SSH configuration? [y/n]: y
✓ Backup created
Disable root login via SSH? [y/n]: y
⚠ Make sure you have another user with sudo access!
Are you sure you want to disable root login? [y/n]: y
✓ Root login disabled
...

✨ Hardening Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Server hardening finished!

Summary of what was configured:
  ✓ Swap configured
  ✓ Firewall (UFW) enabled
  ✓ Fail2ban installed
  ✓ SSH root login disabled
  ✓ SSH password authentication disabled
```

### Setting Up Reverse Proxy

```bash
$ curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/setup-proxy.sh | sudo bash

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

If you prefer to inspect the scripts first:

```bash
# Download both scripts
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/harden-server.sh -o harden-server.sh
curl -fsSL https://raw.githubusercontent.com/angga2oioi/setup-linux-server/main/setup-proxy.sh -o setup-proxy.sh

# Inspect them
cat harden-server.sh
cat setup-proxy.sh

# Make executable
chmod +x harden-server.sh setup-proxy.sh

# Run them
sudo ./harden-server.sh
sudo ./setup-proxy.sh
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

### After Hardening

```bash
# Check swap usage
free -h

# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# View SSH logs
sudo journalctl -u ssh -f

# View fail2ban logs
sudo tail -f /var/log/fail2ban.log

# List banned IPs
sudo fail2ban-client status sshd

# Unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Check system limits
ulimit -n
```

### After Proxy Setup

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

# Check SSL certificate
sudo certbot certificates

# Renew SSL (automatic, but can force)
sudo certbot renew --dry-run
```

## Troubleshooting

### SSH Connection Issues

**Can't connect after hardening:**
- Check if you changed the SSH port: `ssh -p 2222 user@server`
- Make sure you have SSH keys if you disabled password auth
- Check if your IP was banned by fail2ban: `sudo fail2ban-client status sshd`
- Verify firewall allows SSH port: `sudo ufw status`

**Locked out of root:**
- This is why we create a sudo user first!
- Login with your non-root user: `ssh user@server`
- If you need to re-enable root: `sudo nano /etc/ssh/sshd_config`

### Firewall Issues

**Service not accessible:**
```bash
# Check which ports are open
sudo ufw status verbose

# Add missing port
sudo ufw allow 8080/tcp

# Reload firewall
sudo ufw reload
```

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

### Swap Not Working

```bash
# Check if swap is active
swapon --show

# Check swap usage
free -h

# Manually enable if needed
sudo swapon /swapfile
```

## Security Notes

### General
- Both scripts require root access to install packages and modify system configs
- Review the scripts before running if security is a concern
- Always test SSH connection in a new terminal before closing your current session

### Hardening Script
- **IMPORTANT**: Create a non-root sudo user before disabling root login
- Always set up SSH keys before disabling password authentication
- Keep your SSH port number in a safe place if you change it
- Fail2ban will ban IPs after failed login attempts - save your IP somewhere safe
- UFW firewall is enabled by default after configuration

### Proxy Script
- SSL certificates from Let's Encrypt are free and renew automatically
- The script doesn't modify firewall rules - ensure ports 80/443 are open
- Nginx configs are backed up in `/etc/nginx/sites-available/`

### Best Practices
1. Run `harden-server.sh` first on fresh servers
2. Create a non-root user before disabling root login
3. Test SSH keys before disabling password auth
4. Keep a backup of your SSH private key
5. Document any custom ports or settings you configure

## Contributing

Issues and pull requests are welcome! Some ideas for contributions:

### Hardening Script
- [ ] Support for other package managers (yum, pacman, apk)
- [ ] IPv6 firewall rules
- [ ] AppArmor/SELinux configuration
- [ ] Intrusion detection (AIDE, Tripwire)
- [ ] Log monitoring setup (logwatch)
- [ ] Automated backup configuration
- [ ] Docker security hardening

### Proxy Script
- [ ] Support for other package managers (yum, pacman)
- [ ] Multiple backend support (load balancing)
- [ ] Custom SSL certificate support
- [ ] Rate limiting options
- [ ] Basic auth setup
- [ ] WebSocket-specific optimizations
- [ ] HTTP/2 and HTTP/3 support

### Both
- [ ] Combined interactive menu to choose what to configure
- [ ] Dry-run mode to preview changes
- [ ] Rollback functionality
- [ ] Configuration templates
- [ ] Ansible playbook versions

## License

MIT License - feel free to use this however you want!

## Author

Created because I got tired of:
- Googling "nginx reverse proxy config" for every project
- Remembering how to harden a fresh server
- Looking up fail2ban and UFW commands
- Setting up swap for the hundredth time

Now it's just two curl commands. 🎉

---

**Star this repo** if it saved you time! ⭐