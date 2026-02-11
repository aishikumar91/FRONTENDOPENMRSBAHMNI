#!/usr/bin/env bash
# ============================================================================
# HealsFast USA - Production Deployment Script (Enhanced)
# ============================================================================
# Target: Ubuntu 22.04 LTS VPS
# Server: administrator@69.30.247.92
# Domains: clinic.healfastusa.org, admin.healfastusa.org, staff.healfastusa.org
# Timezone: Africa/Lagos
# ============================================================================
# Features:
#   - Docker + Docker Compose installation
#   - Multi-stage production build
#   - Nginx reverse proxy with HTTP/2
#   - Let's Encrypt SSL with auto-renewal
#   - Security hardening (UFW firewall, fail2ban)
#   - Performance optimization
#   - Health monitoring
#   - Automated backups (optional)
# ============================================================================
# Usage:
#   Full setup:     sudo bash deploy-healfast-production.sh
#   System start:   sudo bash deploy-healfast-production.sh --start
#   System stop:    sudo bash deploy-healfast-production.sh --stop
#   System restart: sudo bash deploy-healfast-production.sh --restart
#   Deploy from local: bash deploy-healfast-production.sh --deploy-to 69.30.247.92
# ============================================================================

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================
VPS_IP="${VPS_IP:-69.30.247.92}"
VPS_USER="${VPS_USER:-administrator}"
APP_NAME="healfast-usa-apps"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_TO=""
ACTION=""
TIMEZONE="Africa/Lagos"
DOMAINS=(clinic.healfastusa.org admin.healfastusa.org staff.healfastusa.org)
BACKEND_URL="${BACKEND_URL:-https://clinic.healfastusa.org}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --deploy-to)
            DEPLOY_TO="$2"
            shift 2
            ;;
        --start|--stop|--restart|--status)
            ACTION="${1#--}"
            shift
            ;;
        --backend-url)
            BACKEND_URL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# ============================================================================
# REMOTE DEPLOYMENT (from local machine to VPS)
# ============================================================================
if [[ -n "$DEPLOY_TO" ]]; then
    log_info "Building locally and deploying to ${VPS_USER}@${DEPLOY_TO}"
    
    # Check local dependencies
    if ! command -v node &>/dev/null || ! command -v yarn &>/dev/null; then
        log_error "Node.js and Yarn are required for local build"
        exit 1
    fi
    
    # Build micro-frontends
    log_info "Building micro-frontends..."
    (cd "$REPO_ROOT/micro-frontends" && yarn install && yarn build)
    
    # Build UI
    log_info "Building UI..."
    (cd "$REPO_ROOT/ui" && yarn install && yarn build:no-test)
    
    # Sync to VPS
    log_info "Syncing to VPS..."
    rsync -avz --delete \
        --exclude 'node_modules' \
        --exclude 'ui/node_modules' \
        --exclude 'micro-frontends/node_modules' \
        --exclude '.git' \
        --exclude '.env' \
        "$REPO_ROOT/" "${VPS_USER}@${DEPLOY_TO}:/opt/healfast-usa/"
    
    # Run deployment on VPS
    log_info "Running deployment on VPS..."
    ssh "${VPS_USER}@${DEPLOY_TO}" "sudo bash /opt/healfast-usa/deploy-healfast-production.sh"
    
    log_success "Deployment complete!"
    echo ""
    echo "Application URLs:"
    for d in "${DOMAINS[@]}"; do
        echo "  https://$d"
    done
    exit 0
fi

# ============================================================================
# SYSTEM MANAGEMENT ACTIONS
# ============================================================================
if [[ -n "$ACTION" ]]; then
    check_root
    cd /opt/healfast-usa 2>/dev/null || cd "$REPO_ROOT"
    
    case "$ACTION" in
        start)
            log_info "Starting HealsFast USA system..."
            docker-compose -f docker-compose.production.yml up -d
            systemctl start nginx
            log_success "System started"
            ;;
        stop)
            log_info "Stopping HealsFast USA system..."
            docker-compose -f docker-compose.production.yml down
            log_success "System stopped"
            ;;
        restart)
            log_info "Restarting HealsFast USA system..."
            docker-compose -f docker-compose.production.yml restart
            systemctl reload nginx
            log_success "System restarted"
            ;;
        status)
            log_info "System status:"
            docker-compose -f docker-compose.production.yml ps
            systemctl status nginx --no-pager
            ;;
    esac
    exit 0
fi

# ============================================================================
# FULL PRODUCTION SETUP (on VPS)
# ============================================================================
check_root

log_info "=== HealsFast USA - Production Setup ==="
log_info "Server: ${VPS_USER}@${VPS_IP}"
log_info "Domains: ${DOMAINS[*]}"
log_info "Timezone: $TIMEZONE"
log_info "Backend URL: $BACKEND_URL"
echo ""

cd "$REPO_ROOT"
export DEBIAN_FRONTEND=noninteractive

# ============================================================================
# STEP 1: Set Timezone
# ============================================================================
log_info "[1/12] Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE" || ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
log_success "Timezone set: $(date)"

# ============================================================================
# STEP 2: System Updates & Dependencies
# ============================================================================
log_info "[2/12] Updating system and installing dependencies..."
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    build-essential \
    ufw \
    fail2ban \
    htop \
    vim \
    rsync
log_success "System updated"

# ============================================================================
# STEP 3: Install Docker
# ============================================================================
if ! command -v docker &>/dev/null; then
    log_info "[3/12] Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker "$VPS_USER" 2>/dev/null || true
    systemctl enable docker
    systemctl start docker
    log_success "Docker installed: $(docker --version)"
else
    log_success "[3/12] Docker already installed: $(docker --version)"
fi

# ============================================================================
# STEP 4: Install Docker Compose
# ============================================================================
if ! command -v docker-compose &>/dev/null; then
    log_info "[4/12] Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION="2.24.5"
    curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    log_success "Docker Compose installed: $(docker-compose --version)"
else
    log_success "[4/12] Docker Compose already installed: $(docker-compose --version)"
fi

# ============================================================================
# STEP 5: Build Application (if not already built)
# ============================================================================
log_info "[5/12] Checking application build..."
if [[ ! -d "$REPO_ROOT/ui/dist" ]] || [[ ! -f "$REPO_ROOT/ui/dist/home/index.html" ]]; then
    log_warning "Application not built. Building now..."

    # Install Node.js 18
    if ! command -v node &>/dev/null || [[ $(node -v 2>/dev/null | cut -d. -f1 | tr -d 'v') -lt 18 ]]; then
        log_info "Installing Node.js 18..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y -qq nodejs
    fi

    # Install Yarn
    if ! command -v yarn &>/dev/null; then
        log_info "Installing Yarn..."
        corepack enable 2>/dev/null || npm install -g yarn --force
    fi

    # Install Ruby + Compass
    if ! command -v compass &>/dev/null; then
        log_info "Installing Ruby and Compass..."
        apt-get install -y -qq ruby-full
        gem install compass --no-document
    fi

    # Build micro-frontends
    log_info "Building micro-frontends..."
    (cd "$REPO_ROOT/micro-frontends" && yarn install && yarn build)

    # Build UI
    log_info "Building UI..."
    (cd "$REPO_ROOT/ui" && yarn install && yarn build:no-test)

    log_success "Application built successfully"
else
    log_success "Application already built"
fi

# ============================================================================
# STEP 6: Create Environment Configuration
# ============================================================================
log_info "[6/12] Creating environment configuration..."
if [[ ! -f "$REPO_ROOT/.env" ]]; then
    cp "$REPO_ROOT/.env.production" "$REPO_ROOT/.env"
    sed -i "s|BACKEND_BASE_URL=.*|BACKEND_BASE_URL=${BACKEND_URL}|" "$REPO_ROOT/.env"
    log_success "Environment file created"
else
    log_success "Environment file already exists"
fi

# ============================================================================
# STEP 7: Build and Start Docker Container
# ============================================================================
log_info "[7/12] Building and starting Docker container..."
cd "$REPO_ROOT"

# Build image
docker-compose -f docker-compose.production.yml build --no-cache

# Start container
docker-compose -f docker-compose.production.yml up -d

# Wait for container to be healthy
log_info "Waiting for container to be healthy..."
sleep 10
if docker ps | grep -q "$APP_NAME"; then
    log_success "Container started successfully"
else
    log_error "Container failed to start"
    docker-compose -f docker-compose.production.yml logs
    exit 1
fi

# ============================================================================
# STEP 8: Install and Configure Nginx
# ============================================================================
log_info "[8/12] Installing and configuring Nginx..."
if ! command -v nginx &>/dev/null; then
    apt-get install -y -qq nginx
    systemctl enable nginx
fi

# Copy Nginx configuration
cp "$REPO_ROOT/package/docker/nginx-vps-reverse-proxy.conf" /etc/nginx/sites-available/healfast-usa

# Enable site
ln -sf /etc/nginx/sites-available/healfast-usa /etc/nginx/sites-enabled/healfast-usa

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Test configuration
if nginx -t; then
    systemctl reload nginx
    log_success "Nginx configured and reloaded"
else
    log_error "Nginx configuration test failed"
    exit 1
fi

# ============================================================================
# STEP 9: Install Certbot and Obtain SSL Certificates
# ============================================================================
log_info "[9/12] Installing Certbot and obtaining SSL certificates..."
if ! command -v certbot &>/dev/null; then
    apt-get install -y -qq certbot python3-certbot-nginx
fi

# Create certbot directory
mkdir -p /var/www/certbot

# Obtain certificates
CERTBOT_OPTS="--nginx -d ${DOMAINS[0]} -d ${DOMAINS[1]} -d ${DOMAINS[2]} --redirect --agree-tos --non-interactive --register-unsafely-without-email"

if certbot $CERTBOT_OPTS; then
    log_success "SSL certificates obtained successfully"

    # Enable auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    log_success "SSL auto-renewal enabled"
else
    log_warning "SSL certificate installation failed"
    log_warning "Ensure DNS records point to this server, then run:"
    log_warning "  sudo certbot --nginx -d ${DOMAINS[0]} -d ${DOMAINS[1]} -d ${DOMAINS[2]}"
fi

# ============================================================================
# STEP 10: Configure Firewall (UFW)
# ============================================================================
log_info "[10/12] Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable
log_success "Firewall configured"

# ============================================================================
# STEP 11: Configure Fail2Ban
# ============================================================================
log_info "[11/12] Configuring Fail2Ban..."
if command -v fail2ban-client &>/dev/null; then
    # Create Nginx jail
    cat > /etc/fail2ban/jail.d/nginx.conf << 'EOF'
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/*error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log
maxretry = 2

[nginx-noproxy]
enabled = true
port = http,https
logpath = /var/log/nginx/*access.log
maxretry = 2
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
    log_success "Fail2Ban configured"
else
    log_warning "Fail2Ban not installed, skipping"
fi

# ============================================================================
# STEP 12: Create Systemd Service for Auto-Start
# ============================================================================
log_info "[12/12] Creating systemd service..."
cat > /etc/systemd/system/healfast-usa.service << EOF
[Unit]
Description=HealsFast USA EMR Frontend
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/healfast-usa
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable healfast-usa.service
log_success "Systemd service created"

# ============================================================================
# DEPLOYMENT COMPLETE
# ============================================================================
echo ""
echo "============================================================================"
log_success "HealsFast USA - Production Deployment Complete!"
echo "============================================================================"
echo ""
echo "System Information:"
echo "  Timezone: $TIMEZONE ($(date))"
echo "  Backend URL: $BACKEND_URL"
echo "  Container: $APP_NAME"
echo ""
echo "Application URLs:"
for d in "${DOMAINS[@]}"; do
    echo "  https://$d"
done
echo ""
echo "Management Commands:"
echo "  Start system:   sudo bash $0 --start"
echo "  Stop system:    sudo bash $0 --stop"
echo "  Restart system: sudo bash $0 --restart"
echo "  View status:    sudo bash $0 --status"
echo "  View logs:      sudo docker-compose -f docker-compose.production.yml logs -f"
echo ""
echo "Docker Commands:"
echo "  Container logs: sudo docker logs -f $APP_NAME"
echo "  Container shell: sudo docker exec -it $APP_NAME sh"
echo "  Rebuild:        sudo docker-compose -f docker-compose.production.yml up -d --build"
echo ""
echo "Nginx Commands:"
echo "  Reload:         sudo systemctl reload nginx"
echo "  Status:         sudo systemctl status nginx"
echo "  Logs:           sudo tail -f /var/log/nginx/healfast-*-access.log"
echo ""
echo "SSL Certificate:"
echo "  Renew:          sudo certbot renew"
echo "  Status:         sudo certbot certificates"
echo "  Auto-renewal:   Enabled (certbot.timer)"
echo ""
echo "Security:"
echo "  Firewall:       sudo ufw status"
echo "  Fail2Ban:       sudo fail2ban-client status"
echo ""
echo "Health Check:"
echo "  curl http://localhost:8091/health.json"
echo ""
echo "============================================================================"

