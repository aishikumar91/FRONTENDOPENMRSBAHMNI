# HealsFast USA - Production Deployment Package Summary

## 🎯 Executive Summary

This production deployment package provides enterprise-grade infrastructure for deploying HealsFast USA (Bahmni/OpenMRS EMR frontend) to Ubuntu 22.04 LTS VPS with complete automation, security hardening, and operational procedures.

**Deployment Target:**
- **Server:** 69.30.247.92 (Ubuntu 22.04 LTS)
- **User:** administrator
- **Domains:** clinic.healfastusa.org, admin.healfastusa.org, staff.healfastusa.org
- **Timezone:** Africa/Lagos

---

## 📦 Deliverables

### 1. Docker Infrastructure

#### ✅ Dockerfile.production
**Purpose:** Multi-stage production build with security hardening

**Features:**
- Stage 1: Build micro-frontends (Node.js 18-alpine)
- Stage 2: Build UI with Compass (Ruby + Node.js)
- Stage 3: Production runtime (nginx:1.25-alpine)
- Non-root user (nginx-app:101)
- Health check endpoint (/health.json)
- Timezone: Africa/Lagos
- Optimized layer caching

**Security:**
- Runs as non-root user
- Minimal attack surface (alpine base)
- No build tools in runtime image
- Read-only where possible

---

#### ✅ docker-compose.production.yml
**Purpose:** Production orchestration with environment configuration

**Features:**
- Service: healfast-usa-apps
- Port binding: 127.0.0.1:8091:8091 (localhost only)
- Environment variables from .env file
- Resource limits: 2 CPU, 2GB RAM
- Restart policy: unless-stopped
- Health checks: 30s interval
- Logging: JSON with rotation (10MB max, 3 files)

**Configuration:**
```yaml
services:
  healfast-usa-apps:
    build:
      context: .
      dockerfile: Dockerfile.production
    ports:
      - "127.0.0.1:8091:8091"
    environment:
      - BACKEND_BASE_URL=${BACKEND_BASE_URL}
      - NODE_ENV=production
```

---

#### ✅ .env.production
**Purpose:** Environment configuration template

**Variables:**
- `BACKEND_BASE_URL` - OpenMRS/Bahmni backend URL
- `NODE_ENV` - Production environment flag
- `APP_NAME` - Application name
- `TZ` - Timezone (Africa/Lagos)
- `SSL_DOMAINS` - Domains for SSL certificates
- `DOCKER_CPU_LIMIT` - CPU resource limit
- `DOCKER_MEMORY_LIMIT` - Memory resource limit

**Usage:**
```bash
cp .env.production .env
nano .env  # Edit BACKEND_BASE_URL
```

---

### 2. Nginx Configuration

#### ✅ package/docker/nginx.production.conf
**Purpose:** Main Nginx configuration for Docker container

**Features:**
- Worker processes: auto
- Gzip compression enabled
- Client max body size: 100M
- Keepalive timeout: 65s
- Security headers included

---

#### ✅ package/docker/nginx.default.conf
**Purpose:** Server block configuration for Docker container (port 8091)

**Features:**
- Listen on port 8091
- Root: /usr/share/nginx/html
- Health check endpoint: /health.json
- Static asset caching (1 year for JS/CSS/images)
- No cache for HTML files
- Security headers:
  - X-Frame-Options: SAMEORIGIN
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: 1; mode=block
  - Referrer-Policy: strict-origin-when-cross-origin

**Location Blocks:**
- `/bahmni/` - Main application
- `/home/`, `/clinical/`, `/registration/`, `/admin/`, `/adt/`, `/ot/` - App modules
- `/health.json` - Health check

---

#### ✅ package/docker/nginx-vps-reverse-proxy.conf
**Purpose:** VPS Nginx reverse proxy configuration (to be placed in /etc/nginx/sites-available/)

**Features:**
- HTTP to HTTPS redirect
- HTTP/2 enabled
- SSL/TLS 1.2+ only
- Strong cipher suites
- OCSP stapling
- Rate limiting (10 req/s general, 30 req/s API)
- Separate server blocks for 3 domains:
  - clinic.healfastusa.org
  - admin.healfastusa.org
  - staff.healfastusa.org

**Security Headers:**
- Strict-Transport-Security (HSTS)
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Referrer-Policy
- Permissions-Policy

**Proxy Configuration:**
- Upstream: 127.0.0.1:8091
- WebSocket support
- Connection keepalive
- Proper headers forwarding

---

### 3. Deployment Automation

#### ✅ deploy-healfast-production.sh
**Purpose:** Complete automated deployment script

**Capabilities:**
1. **Full Setup Mode** (default)
   - Install Docker + Docker Compose
   - Set timezone to Africa/Lagos
   - Build application (if needed)
   - Create environment configuration
   - Build and start Docker container
   - Install and configure Nginx
   - Obtain SSL certificates (Let's Encrypt)
   - Configure firewall (UFW)
   - Configure Fail2Ban
   - Create systemd service

2. **Remote Deployment Mode** (`--deploy-to`)
   - Build locally
   - Sync to VPS via rsync
   - Execute deployment on VPS

3. **System Management Mode**
   - `--start` - Start system
   - `--stop` - Stop system
   - `--restart` - Restart system
   - `--status` - View status

**Usage:**
```bash
# Full setup on VPS
sudo bash deploy-healfast-production.sh

# Deploy from local machine
bash deploy-healfast-production.sh --deploy-to 69.30.247.92

# System management
sudo bash deploy-healfast-production.sh --start
sudo bash deploy-healfast-production.sh --restart
```

**Features:**
- Color-coded output (info, success, warning, error)
- Progress tracking (12 steps)
- Error handling
- Idempotent (can run multiple times)
- Comprehensive verification

---

#### ✅ package/docker/configure-env.sh
**Purpose:** Runtime environment configuration injection

**Features:**
- Creates `env-config.js` at container startup
- Injects `BACKEND_BASE_URL` into frontend
- No rebuild required for configuration changes
- Injects script tag into all HTML files

**Generated Configuration:**
```javascript
window.__env = {
  appName: 'HealsFast USA',
  nodeEnv: 'production',
  backendBaseUrl: 'https://clinic.healfastusa.org',
  openmrsRestUrl: 'https://clinic.healfastusa.org/openmrs/ws/rest/v1',
  bahmniRestUrl: 'https://clinic.healfastusa.org/openmrs/ws/rest/v1/bahmnicore'
};
```

---

### 4. Documentation

#### ✅ PRODUCTION_DEPLOYMENT_GUIDE.md (445 lines)
**Comprehensive deployment guide covering:**
- Pre-deployment checklist
- 3 deployment methods (automated, Docker Compose, manual)
- Post-deployment verification (6 categories)
- Rollback strategy (3 methods)
- Operational procedures
- Monitoring & maintenance (daily, weekly, monthly)
- Troubleshooting (6 common issues)
- Security hardening

---

#### ✅ DEPLOYMENT_CHECKLIST.md (175 lines)
**Step-by-step checklist with:**
- Pre-deployment phase (25 items)
- Deployment phase (50 items)
- Post-deployment verification (30 items)
- Documentation & handoff (15 items)
- Sign-off template

---

#### ✅ ROLLBACK_STRATEGY.md (230 lines)
**Disaster recovery procedures:**
- Rollback decision matrix
- 3 rollback methods:
  1. Docker image rollback (5 min)
  2. Git commit rollback (10-15 min)
  3. Full system restore (20-30 min)
- Post-rollback procedures
- Emergency contacts template
- Rollback testing procedures

---

#### ✅ SECURITY_REVIEW.md (280 lines)
**Security audit and hardening:**
- 10 security audit categories
- Verification commands for each
- Security best practices checklist
- HIPAA compliance considerations
- Security incident response procedures

---

#### ✅ DEPLOYMENT_README.md (180 lines)
**Quick start guide:**
- Package overview
- Architecture diagram
- Quick start (2 methods)
- Configuration guide
- System management commands
- Documentation index
- Security features summary

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS (443)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    UFW Firewall                              │
│              (Allow: 22, 80, 443)                            │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Nginx Reverse Proxy (VPS)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  clinic.healfastusa.org:443  (HTTP/2, SSL/TLS 1.2+) │   │
│  │  admin.healfastusa.org:443   (Rate limiting)         │   │
│  │  staff.healfastusa.org:443   (Security headers)      │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ proxy_pass
                         ↓ 127.0.0.1:8091
┌─────────────────────────────────────────────────────────────┐
│           Docker Container (healfast-usa-apps)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Nginx Web Server (nginx:1.25-alpine)               │   │
│  │  - User: nginx-app:101 (non-root)                   │   │
│  │  - Health check: /health.json                       │   │
│  │  - Static files: /usr/share/nginx/html/bahmni/      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Production Readiness Checklist

### Infrastructure
- ✅ Multi-stage Docker build (optimized)
- ✅ Docker Compose orchestration
- ✅ Environment-based configuration
- ✅ Automated deployment script
- ✅ Systemd service for auto-start

### Security
- ✅ Non-root container user
- ✅ Localhost-only port binding
- ✅ HTTPS enforcement
- ✅ SSL/TLS 1.2+ with strong ciphers
- ✅ Security headers (HSTS, X-Frame-Options, etc.)
- ✅ UFW firewall
- ✅ Fail2Ban brute force protection
- ✅ Rate limiting
- ✅ OCSP stapling

### Performance
- ✅ Gzip compression
- ✅ Static asset caching (1 year)
- ✅ HTTP/2 enabled
- ✅ Resource limits (CPU, memory)
- ✅ Connection keepalive
- ✅ Optimized Docker layers

### Monitoring & Operations
- ✅ Health check endpoint
- ✅ Comprehensive logging
- ✅ Log rotation
- ✅ System management commands
- ✅ Rollback procedures

### Documentation
- ✅ Deployment guide (445 lines)
- ✅ Deployment checklist (175 lines)
- ✅ Rollback strategy (230 lines)
- ✅ Security review (280 lines)
- ✅ Quick start README (180 lines)

---

## 🚀 Deployment Time Estimates

| Method | Time | Complexity |
|--------|------|------------|
| **Automated (VPS)** | 15-20 min | Low |
| **Automated (Remote)** | 20-25 min | Low |
| **Docker Compose** | 10-15 min | Medium |
| **Manual** | 30-45 min | High |

---

## 📊 File Summary

| File | Lines | Purpose |
|------|-------|---------|
| Dockerfile.production | 150 | Multi-stage production build |
| docker-compose.production.yml | 80 | Orchestration configuration |
| .env.production | 122 | Environment template |
| nginx.production.conf | 50 | Main Nginx config |
| nginx.default.conf | 120 | Container server block |
| nginx-vps-reverse-proxy.conf | 206 | VPS reverse proxy |
| configure-env.sh | 95 | Runtime configuration |
| deploy-healfast-production.sh | 504 | Deployment automation |
| PRODUCTION_DEPLOYMENT_GUIDE.md | 445 | Complete guide |
| DEPLOYMENT_CHECKLIST.md | 175 | Step-by-step checklist |
| ROLLBACK_STRATEGY.md | 230 | Disaster recovery |
| SECURITY_REVIEW.md | 280 | Security audit |
| DEPLOYMENT_README.md | 180 | Quick start |
| **TOTAL** | **2,637 lines** | **Complete package** |

---

**Package Version:** 1.1.0  
**Created:** 2026-02-11  
**Status:** ✅ Production Ready  
**Maintained by:** HealsFast USA DevOps Team

