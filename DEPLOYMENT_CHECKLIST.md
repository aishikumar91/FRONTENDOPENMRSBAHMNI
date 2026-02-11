# HealsFast USA - Production Deployment Checklist

## Pre-Deployment Phase

### Infrastructure Preparation
- [ ] VPS provisioned (Ubuntu 22.04 LTS, 2+ CPU, 4GB+ RAM, 20GB+ disk)
- [ ] Server IP confirmed: `69.30.247.92`
- [ ] SSH access configured: `ssh administrator@69.30.247.92`
- [ ] SSH key-based authentication enabled
- [ ] Sudo privileges verified for `administrator` user

### DNS Configuration
- [ ] DNS A record created: `clinic.healfastusa.org` → `69.30.247.92`
- [ ] DNS A record created: `admin.healfastusa.org` → `69.30.247.92`
- [ ] DNS A record created: `staff.healfastusa.org` → `69.30.247.92`
- [ ] DNS propagation verified (use `dig` or `nslookup`)
- [ ] TTL set to 300 seconds for quick rollback capability

### Backend Configuration
- [ ] Bahmni/OpenMRS backend URL confirmed
- [ ] Backend API endpoints tested and accessible
- [ ] CORS configuration verified on backend
- [ ] Backend allows requests from frontend domains
- [ ] Database connection tested
- [ ] Backend health check endpoint verified

### Code Repository
- [ ] Repository cloned or updated to latest version
- [ ] All dependencies listed in package.json
- [ ] Build scripts tested locally (optional)
- [ ] Environment variables documented in .env.production

### Security Preparation
- [ ] SSL certificate email address prepared
- [ ] Firewall rules planned (ports 22, 80, 443)
- [ ] Fail2Ban configuration reviewed
- [ ] Security headers configuration reviewed

---

## Deployment Phase

### System Setup
- [ ] Timezone set to `Africa/Lagos`
- [ ] System packages updated: `sudo apt update && sudo apt upgrade`
- [ ] Essential tools installed (curl, git, vim, etc.)

### Docker Installation
- [ ] Docker installed and running
- [ ] Docker version verified: `docker --version`
- [ ] Docker Compose installed
- [ ] Docker Compose version verified: `docker-compose --version`
- [ ] User added to docker group (if needed)

### Application Build
- [ ] Micro-frontends built successfully
- [ ] UI built successfully
- [ ] Build output verified in `ui/dist/`
- [ ] No build errors or warnings

### Environment Configuration
- [ ] `.env` file created from `.env.production`
- [ ] `BACKEND_BASE_URL` configured correctly
- [ ] `TZ` set to `Africa/Lagos`
- [ ] `NODE_ENV` set to `production`
- [ ] All required environment variables set

### Docker Container
- [ ] Docker image built: `docker-compose -f docker-compose.production.yml build`
- [ ] Container started: `docker-compose -f docker-compose.production.yml up -d`
- [ ] Container running: `docker ps | grep healfast-usa-apps`
- [ ] Container healthy: `curl http://localhost:8091/health.json`
- [ ] Container logs checked for errors

### Nginx Configuration
- [ ] Nginx installed
- [ ] Nginx configuration file copied to `/etc/nginx/sites-available/healfast-usa`
- [ ] Symlink created in `/etc/nginx/sites-enabled/`
- [ ] Default site disabled
- [ ] Nginx configuration tested: `sudo nginx -t`
- [ ] Nginx reloaded: `sudo systemctl reload nginx`

### SSL Certificates
- [ ] Certbot installed
- [ ] SSL certificates obtained for all domains
- [ ] Certificate files verified in `/etc/letsencrypt/live/`
- [ ] HTTPS redirect working
- [ ] SSL auto-renewal enabled: `sudo systemctl status certbot.timer`
- [ ] SSL test passed (https://www.ssllabs.com/ssltest/)

### Firewall Configuration
- [ ] UFW installed
- [ ] UFW rules configured (allow 22, 80, 443)
- [ ] UFW enabled: `sudo ufw enable`
- [ ] UFW status verified: `sudo ufw status`

### Fail2Ban Configuration
- [ ] Fail2Ban installed
- [ ] Nginx jails configured
- [ ] Fail2Ban enabled and running
- [ ] Fail2Ban status verified: `sudo fail2ban-client status`

### Systemd Service
- [ ] Systemd service file created: `/etc/systemd/system/healfast-usa.service`
- [ ] Systemd daemon reloaded: `sudo systemctl daemon-reload`
- [ ] Service enabled: `sudo systemctl enable healfast-usa.service`
- [ ] Service status verified: `sudo systemctl status healfast-usa.service`

---

## Post-Deployment Verification

### Health Checks
- [ ] Container health endpoint: `curl http://localhost:8091/health.json`
- [ ] HTTP to HTTPS redirect: `curl -I http://clinic.healfastusa.org`
- [ ] HTTPS response: `curl -I https://clinic.healfastusa.org`
- [ ] All domains accessible via HTTPS

### Application Testing
- [ ] Landing page loads: https://clinic.healfastusa.org
- [ ] Home app loads: https://clinic.healfastusa.org/bahmni/home/
- [ ] Clinical app accessible: https://clinic.healfastusa.org/bahmni/clinical/
- [ ] Registration app accessible: https://clinic.healfastusa.org/bahmni/registration/
- [ ] Admin app accessible: https://admin.healfastusa.org/bahmni/admin/
- [ ] Staff portal accessible: https://staff.healfastusa.org
- [ ] Static assets loading (check browser console)
- [ ] No JavaScript errors in browser console
- [ ] Login functionality tested (requires backend)

### Security Verification
- [ ] Security headers present: `curl -I https://clinic.healfastusa.org`
  - [ ] Strict-Transport-Security
  - [ ] X-Frame-Options
  - [ ] X-Content-Type-Options
  - [ ] X-XSS-Protection
  - [ ] Referrer-Policy
- [ ] Firewall active: `sudo ufw status`
- [ ] Fail2Ban active: `sudo fail2ban-client status`
- [ ] No exposed secrets in logs or configuration
- [ ] Debug mode disabled in production

### Performance Verification
- [ ] Response time acceptable: `time curl -I https://clinic.healfastusa.org`
- [ ] Static assets cached (check Cache-Control headers)
- [ ] Gzip compression enabled (check Content-Encoding)
- [ ] Resource usage acceptable: `docker stats healfast-usa-apps --no-stream`
- [ ] No memory leaks observed

### Monitoring Setup
- [ ] Log rotation configured
- [ ] Health check monitoring configured (optional)
- [ ] Backup procedures documented
- [ ] Alerting configured (optional)

---

## Documentation & Handoff

### Documentation
- [ ] Deployment guide reviewed
- [ ] Operational procedures documented
- [ ] Rollback strategy documented
- [ ] Troubleshooting guide available
- [ ] Emergency contacts documented

### Knowledge Transfer
- [ ] Team trained on deployment process
- [ ] Team trained on operational procedures
- [ ] Team trained on rollback procedures
- [ ] Team has access to all credentials
- [ ] Team has access to VPS

### Backup & Recovery
- [ ] Initial backup created
- [ ] Backup restoration tested
- [ ] Rollback procedure tested
- [ ] Disaster recovery plan documented

---

## Sign-Off

### Deployment Team
- [ ] DevOps Engineer: _________________ Date: _______
- [ ] System Administrator: _________________ Date: _______
- [ ] Technical Lead: _________________ Date: _______

### Stakeholders
- [ ] Project Manager: _________________ Date: _______
- [ ] Product Owner: _________________ Date: _______

---

**Deployment Date:** __________________  
**Deployment Version:** 1.1.0  
**Deployed By:** __________________  
**Notes:**

