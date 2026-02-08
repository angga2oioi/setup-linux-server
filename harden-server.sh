#!/bin/bash

# Note: Script will continue on errors and skip failed steps
# set -e is intentionally NOT used to allow script to continue

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Execute command and continue on error
execute_and_continue() {
    local description="$1"
    shift
    if "$@"; then
        return 0
    else
        print_error "$description failed (continuing...)"
        return 1
    fi
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

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    print_error "Cannot detect OS"
    exit 1
fi

if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
    print_warning "This script is designed for Ubuntu/Debian. It may not work on $OS."
    if ! confirm "Continue anyway?"; then
        exit 1
    fi
fi

print_section "🛡️  Server Hardening Script"
print_info "This script will help you secure your server with best practices"
echo ""

# ============================================================================
# 1. SWAP SETUP
# ============================================================================
print_section "💾 Swap Configuration"

if swapon --show | grep -q "/swapfile"; then
    CURRENT_SWAP=$(free -h | grep Swap | awk '{print $2}')
    print_success "Swap already exists: $CURRENT_SWAP"
    if ! confirm "Do you want to reconfigure swap?"; then
        print_info "Skipping swap configuration"
    else
        print_info "Enter swap size in GB (recommended: 2-4 for small VPS):"
        read -p "Swap size (GB): " SWAP_SIZE
        
        if [ -z "$SWAP_SIZE" ] || ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
            print_error "Invalid swap size. Skipping."
        else
            print_info "Removing old swap..."
            swapoff /swapfile 2>/dev/null || print_warning "Failed to turn off swap"
            rm /swapfile 2>/dev/null || print_warning "Failed to remove swap file"
            
            print_info "Creating ${SWAP_SIZE}GB swap file..."
            if fallocate -l ${SWAP_SIZE}G /swapfile 2>/dev/null; then
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                
                # Make permanent
                if ! grep -q "/swapfile" /etc/fstab; then
                    echo "/swapfile none swap sw 0 0" >> /etc/fstab
                fi
                
                # Set swappiness
                sysctl vm.swappiness=10 2>/dev/null || print_warning "Failed to set swappiness"
                if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
                    echo "vm.swappiness=10" >> /etc/sysctl.conf
                fi
                
                print_success "Swap configured: ${SWAP_SIZE}GB"
            else
                print_error "Failed to create swap file. Skipping."
            fi
        fi
    fi
else
    print_warning "No swap found"
    if confirm "Do you want to create swap?"; then
        print_info "Enter swap size in GB (recommended: 2-4 for small VPS):"
        read -p "Swap size (GB): " SWAP_SIZE
        
        if [ -z "$SWAP_SIZE" ] || ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
            print_error "Invalid swap size. Skipping."
        else
            print_info "Creating ${SWAP_SIZE}GB swap file..."
            if fallocate -l ${SWAP_SIZE}G /swapfile 2>/dev/null; then
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                
                # Make permanent
                echo "/swapfile none swap sw 0 0" >> /etc/fstab
                
                # Set swappiness
                sysctl vm.swappiness=10 2>/dev/null || print_warning "Failed to set swappiness"
                echo "vm.swappiness=10" >> /etc/sysctl.conf
                
                print_success "Swap created: ${SWAP_SIZE}GB"
            else
                print_error "Failed to create swap file. Skipping."
            fi
        fi
    else
        print_info "Skipping swap creation"
    fi
fi

# ============================================================================
# 2. FIREWALL (UFW)
# ============================================================================
print_section "🔥 Firewall Configuration (UFW)"

if command -v ufw &> /dev/null; then
    print_success "UFW is already installed"
else
    if confirm "UFW not found. Install it?"; then
        if apt-get update && apt-get install -y ufw; then
            print_success "UFW installed"
        else
            print_error "Failed to install UFW. Skipping firewall configuration."
        fi
    else
        print_info "Skipping firewall configuration"
    fi
fi

if command -v ufw &> /dev/null; then
    print_info "Current UFW status:"
    ufw status
    echo ""
    
    if confirm "Do you want to configure firewall rules?"; then
        print_warning "Default rules will be:"
        print_warning "  - Allow SSH (port 22)"
        print_warning "  - Allow HTTP (port 80)"
        print_warning "  - Allow HTTPS (port 443)"
        print_warning "  - Deny all other incoming"
        print_warning "  - Allow all outgoing"
        echo ""
        
        if confirm "Apply these rules?"; then
            # Set defaults
            ufw default deny incoming 2>/dev/null || print_warning "Failed to set default deny"
            ufw default allow outgoing 2>/dev/null || print_warning "Failed to set default allow"
            
            # SSH
            read -p "SSH port (default 22): " SSH_PORT
            SSH_PORT=${SSH_PORT:-22}
            ufw allow $SSH_PORT/tcp comment 'SSH' 2>/dev/null || print_warning "Failed to add SSH rule"
            
            # HTTP/HTTPS
            ufw allow 80/tcp comment 'HTTP' 2>/dev/null || print_warning "Failed to add HTTP rule"
            ufw allow 443/tcp comment 'HTTPS' 2>/dev/null || print_warning "Failed to add HTTPS rule"
            
            # Custom ports
            if confirm "Do you want to add any custom ports?"; then
                while true; do
                    read -p "Enter port number (or 'done' to finish): " CUSTOM_PORT
                    if [ "$CUSTOM_PORT" = "done" ]; then
                        break
                    fi
                    if [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]]; then
                        read -p "Protocol (tcp/udp, default tcp): " PROTOCOL
                        PROTOCOL=${PROTOCOL:-tcp}
                        read -p "Comment (optional): " COMMENT
                        if [ -z "$COMMENT" ]; then
                            ufw allow $CUSTOM_PORT/$PROTOCOL
                        else
                            ufw allow $CUSTOM_PORT/$PROTOCOL comment "$COMMENT"
                        fi
                        print_success "Added rule for port $CUSTOM_PORT/$PROTOCOL"
                    else
                        print_error "Invalid port number"
                    fi
                done
            fi
            
            # Enable UFW
            print_warning "Enabling UFW now..."
            if ufw --force enable 2>/dev/null; then
                print_success "Firewall configured and enabled"
                echo ""
                ufw status verbose 2>/dev/null || print_warning "Could not display UFW status"
            else
                print_error "Failed to enable UFW. Skipping."
            fi
        else
            print_info "Skipping firewall configuration"
        fi
    else
        print_info "Skipping firewall configuration"
    fi
fi

# ============================================================================
# 3. FAIL2BAN
# ============================================================================
print_section "🚫 Fail2Ban (Brute Force Protection)"

if command -v fail2ban-client &> /dev/null; then
    print_success "Fail2ban is already installed"
else
    print_info "Fail2ban protects against brute force attacks"
    if confirm "Do you want to install fail2ban?"; then
        if apt-get update && apt-get install -y fail2ban; then
            systemctl enable fail2ban 2>/dev/null || print_warning "Failed to enable fail2ban service"
            systemctl start fail2ban 2>/dev/null || print_warning "Failed to start fail2ban service"
            print_success "Fail2ban installed and started"
        else
            print_error "Failed to install fail2ban. Skipping."
        fi
    else
        print_info "Skipping fail2ban"
    fi
fi

if command -v fail2ban-client &> /dev/null; then
    if confirm "Do you want to configure fail2ban for SSH protection?"; then
        if cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
        then
            if systemctl restart fail2ban 2>/dev/null; then
                print_success "Fail2ban configured for SSH"
                print_info "Settings: 5 attempts in 10 minutes = 1 hour ban"
            else
                print_error "Failed to restart fail2ban service"
            fi
        else
            print_error "Failed to write fail2ban configuration. Skipping."
        fi
    else
        print_info "Skipping fail2ban configuration"
    fi
fi

# ============================================================================
# 4. SSH HARDENING
# ============================================================================
print_section "🔐 SSH Hardening"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

print_warning "This will modify SSH configuration"
print_warning "Backup will be saved to: $SSH_BACKUP"
echo ""

if confirm "Do you want to harden SSH configuration?"; then
    # Backup
    if cp $SSH_CONFIG $SSH_BACKUP 2>/dev/null; then
        print_success "Backup created: $SSH_BACKUP"
    else
        print_error "Failed to create backup. Skipping SSH hardening."
    fi
    
    # Only proceed if backup was successful
    if [ -f $SSH_BACKUP ]; then
    # Disable root login
    if confirm "Disable root login via SSH? (Recommended if you have another sudo user)"; then
        print_warning "Make sure you have another user with sudo access!"
        if confirm "Are you sure you want to disable root login?"; then
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG
            print_success "Root login disabled"
        fi
    fi
    
    # Disable password authentication
    if confirm "Disable password authentication? (Requires SSH key setup)"; then
        print_warning "Make sure you have SSH keys configured!"
        print_warning "You can test with: ssh -i ~/.ssh/your_key user@server"
        if confirm "Are you SURE? You could lock yourself out!"; then
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG
            sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' $SSH_CONFIG
            sed -i 's/^#*UsePAM.*/UsePAM no/' $SSH_CONFIG
            print_success "Password authentication disabled"
        fi
    fi
    
    # Change SSH port
    if confirm "Change default SSH port? (Security through obscurity)"; then
        CURRENT_PORT=$(grep "^Port " $SSH_CONFIG | awk '{print $2}')
        CURRENT_PORT=${CURRENT_PORT:-22}
        print_info "Current SSH port: $CURRENT_PORT"
        read -p "Enter new SSH port (1024-65535, e.g., 2222): " NEW_SSH_PORT
        
        if [[ "$NEW_SSH_PORT" =~ ^[0-9]+$ ]] && [ "$NEW_SSH_PORT" -ge 1024 ] && [ "$NEW_SSH_PORT" -le 65535 ]; then
            sed -i "s/^#*Port .*/Port $NEW_SSH_PORT/" $SSH_CONFIG
            print_success "SSH port changed to: $NEW_SSH_PORT"
            print_warning "Remember to update your firewall rules!"
            if command -v ufw &> /dev/null; then
                if confirm "Update UFW to allow port $NEW_SSH_PORT?"; then
                    ufw allow $NEW_SSH_PORT/tcp comment 'SSH'
                    if [ "$CURRENT_PORT" != "$NEW_SSH_PORT" ]; then
                        ufw delete allow $CURRENT_PORT/tcp
                    fi
                    print_success "Firewall updated"
                fi
            fi
        else
            print_error "Invalid port number. Skipping."
        fi
    fi
    
    # Other SSH hardening
    if confirm "Apply other SSH security settings? (Protocol 2, no X11 forwarding, etc.)"; then
        sed -i 's/^#*Protocol.*/Protocol 2/' $SSH_CONFIG
        sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' $SSH_CONFIG
        sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' $SSH_CONFIG
        sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' $SSH_CONFIG
        sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' $SSH_CONFIG
        print_success "Additional SSH hardening applied"
    fi
    
    # Restart SSH
    print_warning "SSH configuration changed. Need to restart SSH service."
    if confirm "Restart SSH now? (Your current session will remain active)"; then
        if systemctl restart sshd 2>/dev/null; then
            print_success "SSH service restarted"
            print_warning "Test new SSH connection in another terminal before closing this one!"
        else
            print_error "Failed to restart SSH service"
        fi
    else
        print_warning "Remember to restart SSH: sudo systemctl restart sshd"
    fi
    
    fi  # End of backup check
else
    print_info "Skipping SSH hardening"
fi

# ============================================================================
# 5. AUTOMATIC SECURITY UPDATES
# ============================================================================
print_section "🔄 Automatic Security Updates"

if confirm "Enable automatic security updates?"; then
    if apt-get update && apt-get install -y unattended-upgrades; then
        dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || print_warning "Failed to configure unattended-upgrades"
        print_success "Automatic security updates enabled"
    else
        print_error "Failed to install unattended-upgrades. Skipping."
    fi
else
    print_info "Skipping automatic updates"
fi

# ============================================================================
# 6. SYSTEM LIMITS & PERFORMANCE
# ============================================================================
print_section "⚡ System Limits & Performance"

if confirm "Increase system limits for better performance?"; then
    print_info "This will increase file descriptors and connection limits"
    
    # File descriptors
    if cat >> /etc/security/limits.conf <<EOF

# Increased limits for better performance
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
    then
        print_success "File descriptor limits configured"
    else
        print_error "Failed to configure file descriptor limits"
    fi
    
    # Sysctl tweaks
    if cat >> /etc/sysctl.conf <<EOF

# Performance and security tweaks
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
EOF
    then
        sysctl -p 2>/dev/null || print_warning "Failed to apply sysctl settings"
        print_success "System limits increased"
    else
        print_error "Failed to configure sysctl settings"
    fi
else
    print_info "Skipping system limits"
fi

# ============================================================================
# 7. TIMEZONE
# ============================================================================
print_section "🌍 Timezone Configuration"

CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
print_info "Current timezone: $CURRENT_TZ"

if confirm "Do you want to change the timezone?"; then
    print_info "Common timezones:"
    print_info "  UTC"
    print_info "  America/New_York"
    print_info "  America/Los_Angeles"
    print_info "  Europe/London"
    print_info "  Asia/Tokyo"
    print_info "  Asia/Singapore"
    echo ""
    read -p "Enter timezone (or leave blank to skip): " NEW_TZ
    
    if [ ! -z "$NEW_TZ" ]; then
        if timedatectl set-timezone "$NEW_TZ" 2>/dev/null; then
            print_success "Timezone set to: $NEW_TZ"
        else
            print_error "Invalid timezone. Run 'timedatectl list-timezones' to see all options"
        fi
    fi
else
    print_info "Keeping current timezone"
fi

# ============================================================================
# 8. CREATE NON-ROOT USER
# ============================================================================
print_section "👤 User Management"

if confirm "Do you want to create a non-root sudo user?"; then
    read -p "Enter username: " NEW_USER
    
    if [ -z "$NEW_USER" ]; then
        print_error "Username cannot be empty. Skipping."
    elif id "$NEW_USER" &>/dev/null; then
        print_warning "User $NEW_USER already exists"
    else
        if adduser --gecos "" $NEW_USER 2>/dev/null && usermod -aG sudo $NEW_USER 2>/dev/null; then
            print_success "User $NEW_USER created with sudo privileges"
            
            if confirm "Do you want to copy SSH keys from root to $NEW_USER?"; then
                if [ -d /root/.ssh ]; then
                    mkdir -p /home/$NEW_USER/.ssh 2>/dev/null
                    cp /root/.ssh/authorized_keys /home/$NEW_USER/.ssh/ 2>/dev/null || print_warning "No authorized_keys found"
                    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh 2>/dev/null
                    chmod 700 /home/$NEW_USER/.ssh 2>/dev/null
                    chmod 600 /home/$NEW_USER/.ssh/authorized_keys 2>/dev/null
                    print_success "SSH keys copied to $NEW_USER"
                else
                    print_warning "No SSH keys found in /root/.ssh"
                fi
            fi
        else
            print_error "Failed to create user $NEW_USER. Skipping."
        fi
    fi
else
    print_info "Skipping user creation"
fi

# ============================================================================
# SUMMARY
# ============================================================================
print_section "✨ Hardening Complete!"

echo ""
print_success "Server hardening finished!"
echo ""
print_info "Summary of what was configured:"
echo ""

if swapon --show | grep -q "/swapfile"; then
    echo "  ✓ Swap configured"
fi

if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "  ✓ Firewall (UFW) enabled"
fi

if command -v fail2ban-client &> /dev/null; then
    echo "  ✓ Fail2ban installed"
fi

if grep -q "PermitRootLogin no" $SSH_CONFIG; then
    echo "  ✓ SSH root login disabled"
fi

if grep -q "PasswordAuthentication no" $SSH_CONFIG; then
    echo "  ✓ SSH password authentication disabled"
fi

echo ""
print_warning "IMPORTANT REMINDERS:"
print_warning "  1. Test SSH connection in a new terminal before closing this one"
print_warning "  2. Make sure you can login with SSH keys if you disabled passwords"
print_warning "  3. Remember any custom SSH port you configured"
print_warning "  4. Review firewall rules: sudo ufw status verbose"
echo ""
print_info "Useful commands:"
print_info "  sudo ufw status         - Check firewall status"
print_info "  sudo fail2ban-client status - Check fail2ban status"
print_info "  free -h                 - Check swap usage"
print_info "  sudo journalctl -u ssh  - Check SSH logs"
echo ""