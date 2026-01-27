#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

confirm() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "Nginx Reverse Proxy Setup Script"
echo ""

# 1. Check if nginx is installed
print_info "Checking for nginx..."
if ! command -v nginx &> /dev/null; then
    print_warning "Nginx is not installed"
    if confirm "Do you want to install nginx?"; then
        print_info "Installing nginx..."
        apt-get update
        apt-get install -y nginx
        systemctl enable nginx
        systemctl start nginx
        print_success "Nginx installed successfully"
    else
        print_error "Nginx is required for this script. Exiting."
        exit 1
    fi
else
    print_success "Nginx is already installed"
fi

echo ""

# 2. Check if certbot is installed
print_info "Checking for certbot..."
if ! command -v certbot &> /dev/null; then
    print_warning "Certbot is not installed"
    if confirm "Do you want to install certbot?"; then
        print_info "Installing certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        print_success "Certbot installed successfully"
    else
        print_warning "Certbot not installed. SSL setup will be skipped."
    fi
else
    print_success "Certbot is already installed"
fi

echo ""

# 3. Get domain name
print_info "Enter the domain name for the reverse proxy:"
read -p "Domain (e.g., api.example.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    print_error "Domain cannot be empty. Exiting."
    exit 1
fi

print_info "Domain set to: $DOMAIN"
echo ""

# 4. Check if config exists
CONFIG_FILE="/etc/nginx/sites-available/$DOMAIN"
CONFIG_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

if [ -f "$CONFIG_FILE" ]; then
    print_warning "Configuration file already exists: $CONFIG_FILE"
    if ! confirm "Do you want to overwrite it?"; then
        print_info "Keeping existing configuration"
    else
        # Get proxy details and create new config
        print_info "Enter the backend server details:"
        read -p "IP address (e.g., 127.0.0.1): " PROXY_IP
        read -p "Port (e.g., 3000): " PROXY_PORT
        
        if [ -z "$PROXY_IP" ] || [ -z "$PROXY_PORT" ]; then
            print_error "IP and Port cannot be empty. Exiting."
            exit 1
        fi
        
        print_info "Creating nginx configuration for $DOMAIN -> $PROXY_IP:$PROXY_PORT"
        
        cat > "$CONFIG_FILE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://$PROXY_IP:$PROXY_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        
        print_success "Configuration file created"
    fi
else
    # Config doesn't exist, create new one
    print_info "No existing configuration found. Creating new one..."
    echo ""
    print_info "Enter the backend server details:"
    read -p "IP address (e.g., 127.0.0.1): " PROXY_IP
    read -p "Port (e.g., 3000): " PROXY_PORT
    
    if [ -z "$PROXY_IP" ] || [ -z "$PROXY_PORT" ]; then
        print_error "IP and Port cannot be empty. Exiting."
        exit 1
    fi
    
    print_info "Creating nginx configuration for $DOMAIN -> $PROXY_IP:$PROXY_PORT"
    
    cat > "$CONFIG_FILE" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://$PROXY_IP:$PROXY_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    print_success "Configuration file created"
fi

echo ""

# 5. Enable the site
if [ ! -L "$CONFIG_ENABLED" ]; then
    print_info "Enabling site..."
    ln -s "$CONFIG_FILE" "$CONFIG_ENABLED"
    print_success "Site enabled"
else
    print_success "Site is already enabled"
fi

# 6. Test nginx configuration
print_info "Testing nginx configuration..."
if nginx -t; then
    print_success "Nginx configuration is valid"
    print_info "Reloading nginx..."
    systemctl reload nginx
    print_success "Nginx reloaded"
else
    print_error "Nginx configuration test failed. Please check the configuration."
    exit 1
fi

echo ""

# 7. SSL Setup with Let's Encrypt
if command -v certbot &> /dev/null; then
    if confirm "Do you want to setup SSL with Let's Encrypt for $DOMAIN?"; then
        print_warning "Make sure:"
        print_warning "  1. DNS is pointing to this server"
        print_warning "  2. Port 80 and 443 are open"
        echo ""
        
        read -p "Enter your email address for Let's Encrypt: " EMAIL
        
        if [ -z "$EMAIL" ]; then
            print_error "Email cannot be empty. Skipping SSL setup."
        else
            print_info "Running certbot..."
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect
            
            if [ $? -eq 0 ]; then
                print_success "SSL certificate installed successfully!"
            else
                print_error "SSL setup failed. You can run certbot manually later."
            fi
        fi
    else
        print_info "Skipping SSL setup"
    fi
else
    print_warning "Certbot not installed. Skipping SSL setup."
fi

echo ""
print_success "✨ Setup complete!"
print_info "Your reverse proxy is configured at: $DOMAIN"
print_info "Config file: $CONFIG_FILE"
echo ""
print_info "To view logs: sudo tail -f /var/log/nginx/access.log"
print_info "To edit config: sudo nano $CONFIG_FILE"
print_info "To reload nginx: sudo systemctl reload nginx"