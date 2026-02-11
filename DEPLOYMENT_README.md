# HealsFast USA - Production Deployment Package

## 📋 Overview

This package contains enterprise-grade production deployment infrastructure for HealsFast USA, a Bahmni/OpenMRS EMR frontend application.

**Target Environment:**
- **Server:** Ubuntu 22.04 LTS VPS
- **IP:** 69.30.247.92
- **User:** administrator
- **Domains:** clinic.healfastusa.org, admin.healfastusa.org, staff.healfastusa.org
- **Timezone:** Africa/Lagos

---

## 📦 Package Contents

### Core Deployment Files

1. **Dockerfile.production**
   - Multi-stage production build
   - Node.js 18 + Ruby/Compass build environment
   - Nginx-alpine runtime (1.25)
   - Non-root user security
   - Health check endpoint

2. **docker-compose.production.yml**
   - Production orchestration
   - Environment variable configuration
   - Resource limits (2 CPU, 2GB RAM)
   - Health checks and restart policies
   - Localhost-only port binding

3. **deploy-healfast-production.sh**
   - Automated deployment script
   - Full system setup (Docker, Nginx, SSL, Firewall)
   - Remote deployment capability
   - System management (start/stop/restart)

4. **.env.production**
   - Environment configuration template
   - Backend URL configuration
   - Timezone and resource settings

### Nginx Configuration

5. **package/docker/nginx.production.conf**
   - Main Nginx configuration for Docker container
   - Gzip compression
   - Security settings

6. **package/docker/nginx.default.conf**
   - Server block for Docker container (port 8091)
   - Static asset caching
   - Security headers
   - Health check endpoint

7. **package/docker/nginx-vps-reverse-proxy.conf**
   - VPS reverse proxy configuration
   - HTTPS/HTTP/2 enabled
   - SSL configuration
   - Rate limiting
   - Separate server blocks for 3 domains

### Utilities

8. **package/docker/configure-env.sh**
   - Runtime environment configuration
   - Backend URL injection
   - No rebuild required for config changes

### Documentation

9. **PRODUCTION_DEPLOYMENT_GUIDE.md**
   - Complete deployment guide
   - Pre-deployment checklist
   - Post-deployment verification
   - Monitoring and maintenance
   - Troubleshooting

10. **DEPLOYMENT_CHECKLIST.md**
    - Step-by-step deployment checklist
    - Verification steps
    - Sign-off template

11. **ROLLBACK_STRATEGY.md**
    - Multiple rollback methods
    - Decision matrix
    - Post-rollback procedures
    - Emergency contacts

12. **SECURITY_REVIEW.md**
    - Security audit checklist
    - Hardening verification
    - Compliance guidelines
    - Incident response

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

**On VPS:**
```bash
cd /opt
sudo git clone https://github.com/aishikumar91/FRONTENDOPENMRSBAHMNI healfast-usa
cd healfast-usa
sudo bash deploy-healfast-production.sh
```

**From Local Machine:**
```bash
bash deploy-healfast-production.sh --deploy-to 69.30.247.92
```

### Option 2: Docker Compose

```bash
# On VPS
cd /opt/healfast-usa
cp .env.production .env
nano .env  # Configure BACKEND_BASE_URL

docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d
```

---

## 🏗️ Architecture

```
Internet (HTTPS)
    ↓
Nginx Reverse Proxy (VPS)
    ├── clinic.healfastusa.org:443
    ├── admin.healfastusa.org:443
    └── staff.healfastusa.org:443
    ↓
Docker Container (localhost:8091)
    ├── Nginx Web Server
    └── Static Files (/usr/share/nginx/html/bahmni/)
```

**Security Layers:**
1. UFW Firewall (ports 22, 80, 443 only)
2. Fail2Ban (brute force protection)
3. Nginx rate limiting
4. HTTPS/TLS 1.2+ only
5. Security headers (HSTS, X-Frame-Options, etc.)
6. Non-root container user
7. Localhost-only Docker port binding

---

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Backend Configuration
BACKEND_BASE_URL=https://clinic.healfastusa.org

# Application Settings
NODE_ENV=production
APP_NAME=HealsFast USA
TZ=Africa/Lagos

# SSL Domains
SSL_DOMAINS=clinic.healfastusa.org,admin.healfastusa.org,staff.healfastusa.org

# Resource Limits
DOCKER_CPU_LIMIT=2.0
DOCKER_MEMORY_LIMIT=2G
```

### Backend URL Configuration

The application uses `localStorage` for runtime backend configuration:
- Set via `window.__env.backendBaseUrl` in `env-config.js`
- Injected at container startup by `configure-env.sh`
- No rebuild required to change backend URL

---

## 📊 System Management

### Start System
```bash
sudo bash deploy-healfast-production.sh --start
```

### Stop System
```bash
sudo bash deploy-healfast-production.sh --stop
```

### Restart System
```bash
sudo bash deploy-healfast-production.sh --restart
```

### View Logs
```bash
# Container logs
docker logs -f healfast-usa-apps

# Nginx logs
sudo tail -f /var/log/nginx/healfast-clinic-access.log
```

### Health Check
```bash
curl http://localhost:8091/health.json
```

---

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| **PRODUCTION_DEPLOYMENT_GUIDE.md** | Complete deployment guide with troubleshooting |
| **DEPLOYMENT_CHECKLIST.md** | Step-by-step checklist for deployment |
| **ROLLBACK_STRATEGY.md** | Rollback procedures and disaster recovery |
| **SECURITY_REVIEW.md** | Security audit and hardening guide |
| **DEPLOYMENT_README.md** | This file - overview and quick start |

---

## 🔐 Security Features

- ✅ Non-root container user (nginx-app:101)
- ✅ Localhost-only port binding (127.0.0.1:8091)
- ✅ HTTPS enforcement with HTTP/2
- ✅ Security headers (HSTS, X-Frame-Options, CSP, etc.)
- ✅ UFW firewall (ports 22, 80, 443 only)
- ✅ Fail2Ban brute force protection
- ✅ Rate limiting (10 req/s general, 30 req/s API)
- ✅ SSL/TLS 1.2+ with strong ciphers
- ✅ OCSP stapling
- ✅ Resource limits (CPU, memory)
- ✅ Health monitoring
- ✅ Log rotation

---

## 🎯 Production Readiness

- ✅ Multi-stage Docker build (optimized size)
- ✅ Environment-based configuration
- ✅ Automated deployment script
- ✅ SSL certificate automation (Let's Encrypt)
- ✅ Systemd service for auto-start
- ✅ Health checks and monitoring
- ✅ Comprehensive documentation
- ✅ Rollback strategy
- ✅ Security hardening
- ✅ Performance optimization (gzip, caching)

---

## 📞 Support

For issues or questions:
1. Check **PRODUCTION_DEPLOYMENT_GUIDE.md** troubleshooting section
2. Review logs: `docker logs healfast-usa-apps`
3. Contact: administrator@healfastusa.org

---

**Version:** 1.1.0  
**Last Updated:** 2026-02-11  
**Maintained by:** HealsFast USA DevOps Team

