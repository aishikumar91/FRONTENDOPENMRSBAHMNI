#!/usr/bin/env bash
#
# HealFast USA – single script to install, build, run, and configure SSL on Ubuntu 22 LTS (VPS)
# Target server: administrator@69.30.247.92
# Domains: clinic.healfastusa.org, admin.healfastusa.org, staff.healfastusa.org (SSL via Let's Encrypt)
# Timezone: Africa/Lagos
#
# Before running: point DNS A records for clinic.healfastusa.org, admin.healfastusa.org,
# and staff.healfastusa.org to 69.30.247.92 so Certbot can issue certificates.
#
# Usage:
#   Run full setup (install deps, build, SSL, start system):
#     sudo bash run-healfast-on-vps.sh
#
#   Run system only (start/restart app + Nginx; use after reboot or to bring system up):
#     sudo bash run-healfast-on-vps.sh --run-system
#
#   Copy repo to VPS then run on server:
#     rsync -avz --exclude node_modules --exclude ui/node_modules --exclude micro-frontends/node_modules \
#       ./openmrs-module-bahmniapps/ administrator@69.30.247.92:/opt/healfast-usa/
#     ssh administrator@69.30.247.92
#     sudo bash /opt/healfast-usa/run-healfast-on-vps.sh
#
#   Deploy from local machine (build + rsync + run on VPS):
#     bash run-healfast-on-vps.sh --deploy-to 69.30.247.92
#
set -e

VPS_IP="${VPS_IP:-69.30.247.92}"
VPS_USER="${VPS_USER:-administrator}"
APP_NAME="healfast-usa-apps"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_TO=""
RUN_SYSTEM_ONLY=""
TIMEZONE="Africa/Lagos"
DOMAINS=(clinic.healfastusa.org admin.healfastusa.org staff.healfastusa.org)

while [[ $# -gt 0 ]]; do
  case $1 in
    --deploy-to)
      DEPLOY_TO="$2"
      shift 2
      ;;
    --run-system)
      RUN_SYSTEM_ONLY=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# --- Run on remote VPS via SSH ---
if [[ -n "$DEPLOY_TO" ]]; then
  echo "=== Building locally and deploying to ${VPS_USER}@${DEPLOY_TO} ==="
  if ! command -v node &>/dev/null || ! command -v yarn &>/dev/null; then
    echo "Node and Yarn are required for local build. Install them and run again."
    exit 1
  fi
  echo "Building micro-frontends..."
  (cd "$REPO_ROOT/micro-frontends" && yarn install && yarn build)
  echo "Building UI..."
  (cd "$REPO_ROOT/ui" && yarn install && yarn ci)
  echo "Syncing to VPS..."
  rsync -avz --delete \
    --exclude 'node_modules' \
    --exclude 'ui/node_modules' \
    --exclude 'micro-frontends/node_modules' \
    --exclude '.git' \
    "$REPO_ROOT/" "${VPS_USER}@${DEPLOY_TO}:/opt/healfast-usa/"
  echo "Running remote script on VPS..."
  ssh "${VPS_USER}@${DEPLOY_TO}" "sudo bash -s vps-only" < "$REPO_ROOT/run-healfast-on-vps.sh"
  echo "Done. App available at:"
  for d in "${DOMAINS[@]}"; do echo "  https://$d"; done
  exit 0
fi

# --- If invoked with vps-only: set timezone, build Docker, run container (no Nginx/SSL) ---
if [[ "${1:-}" == "vps-only" ]]; then
  sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
  cd /opt/healfast-usa
  sudo docker build -f package/docker/Dockerfile -t "$APP_NAME" .
  sudo docker stop "$APP_NAME" 2>/dev/null || true
  sudo docker rm "$APP_NAME" 2>/dev/null || true
  sudo docker run -d -p 127.0.0.1:8091:8091 --name "$APP_NAME" --restart unless-stopped "$APP_NAME"
  echo "HealFast USA container running (localhost:8091). Timezone: $TIMEZONE"
  exit 0
fi

# --- Run system only: start/restart app container + Nginx (no install/build) ---
if [[ -n "$RUN_SYSTEM_ONLY" ]]; then
  echo "=== HealFast USA – starting system ==="
  sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
  echo "  Timezone: $TIMEZONE ($(date))"
  if [[ -d /opt/healfast-usa ]]; then
    cd /opt/healfast-usa
  else
    cd "$REPO_ROOT"
  fi
  # Start or restart app container
  if sudo docker images -q "$APP_NAME" | grep -q .; then
    sudo docker stop "$APP_NAME" 2>/dev/null || true
    sudo docker rm "$APP_NAME" 2>/dev/null || true
    sudo docker run -d -p 127.0.0.1:8091:8091 --name "$APP_NAME" --restart unless-stopped "$APP_NAME"
    echo "  App container: started"
  else
    echo "  App image $APP_NAME not found. Run full setup first: sudo bash $0"
    exit 1
  fi
  # Ensure Nginx is enabled and running
  if command -v nginx &>/dev/null; then
    sudo systemctl enable nginx 2>/dev/null || true
    sudo systemctl start nginx 2>/dev/null || true
    sudo systemctl reload nginx 2>/dev/null || true
    echo "  Nginx: running"
  fi
  echo ""
  echo "System is running. URLs:"
  for d in "${DOMAINS[@]}"; do echo "  https://$d"; done
  echo "  Logs: sudo docker logs -f $APP_NAME"
  exit 0
fi

# ========== Run on VPS (Ubuntu 22) – full setup ==========
echo "=== HealFast USA – full setup on Ubuntu 22 (${VPS_USER}@${VPS_IP}) ==="
echo "  Domains: ${DOMAINS[*]}"
echo "  Timezone: $TIMEZONE"
echo ""
cd "$REPO_ROOT"

export DEBIAN_FRONTEND=noninteractive

# 0) Set timezone
echo "[0/8] Setting timezone to $TIMEZONE..."
sudo timedatectl set-timezone "$TIMEZONE" || sudo ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
echo "  Current time: $(date)"

# 1) System packages
echo "[1/8] Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl git build-essential

# 2) Node.js 18 LTS
if ! command -v node &>/dev/null || [[ $(node -v 2>/dev/null | cut -d. -f1 | tr -d 'v') -lt 18 ]]; then
  echo "[2/8] Installing Node.js 18..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y -qq nodejs
fi
node -v

# 3) Yarn (use corepack if Node 18+; else npm global; overwrite if /usr/bin/yarn exists)
if ! command -v yarn &>/dev/null || ! yarn -v &>/dev/null; then
  echo "[3/8] Installing Yarn..."
  sudo corepack enable 2>/dev/null || true
  if ! command -v yarn &>/dev/null || ! yarn -v &>/dev/null; then
    sudo rm -f /usr/bin/yarn /usr/bin/yarnpkg 2>/dev/null || true
    sudo npm install -g yarn --force
  fi
fi
yarn -v

# 4) Ruby + Compass (for UI build)
if ! command -v compass &>/dev/null; then
  echo "[4/8] Installing Ruby and Compass..."
  sudo apt-get install -y -qq ruby-full
  sudo gem install compass
fi
compass -v

# 5) Docker
if ! command -v docker &>/dev/null; then
  echo "[5/8] Installing Docker..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin
  sudo usermod -aG docker "$USER" 2>/dev/null || true
fi
sudo docker -v

# 6) Build and run HealFast USA container (bind to localhost only; Nginx will proxy)
echo "[6/8] Building HealFast USA and starting container..."

if [[ ! -d "$REPO_ROOT/ui/dist" ]] || [[ ! -f "$REPO_ROOT/ui/dist/index.html" ]]; then
  echo "  Building micro-frontends..."
  (cd "$REPO_ROOT/micro-frontends" && yarn install && yarn build)
  echo "  Building UI..."
  (cd "$REPO_ROOT/ui" && yarn install && yarn ci)
fi

sudo docker build -f "$REPO_ROOT/package/docker/Dockerfile" -t "$APP_NAME" "$REPO_ROOT"
sudo docker stop "$APP_NAME" 2>/dev/null || true
sudo docker rm "$APP_NAME" 2>/dev/null || true
sudo docker run -d -p 127.0.0.1:8091:8091 --name "$APP_NAME" --restart unless-stopped "$APP_NAME"

# 7) Nginx + SSL (Let's Encrypt)
echo "[7/8] Installing Nginx and Certbot..."
sudo apt-get install -y -qq nginx certbot python3-certbot-nginx

# Nginx config for HealFast USA (HTTP first; certbot adds SSL)
HEALFAST_NGINX_HTTP="/etc/nginx/sites-available/healfast-usa"
sudo tee "$HEALFAST_NGINX_HTTP" > /dev/null << 'NGINX_HTTP'
# HealFast USA – HTTP (for initial certbot)
server {
    listen 80;
    listen [::]:80;
    server_name clinic.healfastusa.org admin.healfastusa.org staff.healfastusa.org;
    location / {
        proxy_pass http://127.0.0.1:8091;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_HTTP

sudo ln -sf /etc/nginx/sites-available/healfast-usa /etc/nginx/sites-enabled/healfast-usa 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t && sudo systemctl enable nginx && sudo systemctl reload nginx

echo "[8/8] Obtaining SSL certificates (Let's Encrypt)..."
CERTBOT_OPTS="--nginx -d clinic.healfastusa.org -d admin.healfastusa.org -d staff.healfastusa.org --redirect"
# Non-interactive when no TTY (e.g. piped from deploy)
if [[ ! -t 0 ]]; then
  CERTBOT_OPTS="$CERTBOT_OPTS --non-interactive --agree-tos --register-unsafely-without-email"
fi
if ! sudo certbot $CERTBOT_OPTS; then
  echo "  Note: If SSL failed, ensure DNS for clinic/admin/staff.healfastusa.org points to this server, then run:"
  echo "    sudo certbot --nginx -d clinic.healfastusa.org -d admin.healfastusa.org -d staff.healfastusa.org"
fi

# Ensure SSL config is in place (certbot may have modified the file)
if sudo test -f /etc/letsencrypt/live/clinic.healfastusa.org/fullchain.pem 2>/dev/null; then
  echo "  SSL certificates installed."
  sudo systemctl enable certbot.timer 2>/dev/null || true
fi

echo ""
echo "=== HealFast USA setup complete – system is running ==="
echo "  Timezone: $TIMEZONE ($(date))"
echo "  App (container): http://127.0.0.1:8091"
echo "  Public URLs (HTTPS):"
for d in "${DOMAINS[@]}"; do echo "    https://$d"; done
echo ""
echo "  To run system again (after reboot or to restart):"
echo "    sudo bash $(basename "$0") --run-system"
echo ""
echo "  Stop app:  sudo docker stop $APP_NAME"
echo "  Logs:      sudo docker logs -f $APP_NAME"
echo "  Nginx:     sudo systemctl status nginx"
echo "  Renew SSL: sudo certbot renew (auto-renewal enabled)"
echo ""
