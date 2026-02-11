# HealsFast USA - Production Deployment Guide

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Methods](#deployment-methods)
3. [Post-Deployment Verification](#post-deployment-verification)
4. [Rollback Strategy](#rollback-strategy)
5. [Operational Procedures](#operational-procedures)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)
8. [Security Hardening](#security-hardening)

---

## Pre-Deployment Checklist

### DNS Configuration
- [ ] DNS A records configured for all domains pointing to `69.30.247.92`:
  - `clinic.healfastusa.org`
  - `admin.healfastusa.org`
  - `staff.healfastusa.org`
- [ ] DNS propagation verified (use `dig` or `nslookup`)
- [ ] TTL reduced to 300 seconds (5 minutes) for quick rollback if needed

### Server Access
- [ ] SSH access confirmed: `ssh administrator@69.30.247.92`
- [ ] SSH key-based authentication configured (recommended)
- [ ] Sudo privileges verified for `administrator` user
- [ ] Server timezone set to `Africa/Lagos`

### Backend Configuration
- [ ] Bahmni/OpenMRS backend URL confirmed
- [ ] Backend API endpoints accessible
- [ ] CORS configuration verified on backend
- [ ] Database connection tested

### Local Build Environment (if building locally)
- [ ] Node.js 18+ installed
- [ ] Yarn package manager installed
- [ ] Ruby and Compass installed
- [ ] Git repository cloned and up-to-date

### VPS Requirements
- [ ] Ubuntu 22.04 LTS confirmed
- [ ] Minimum 2 CPU cores, 4GB RAM
- [ ] At least 20GB free disk space
- [ ] Ports 22, 80, 443 accessible

---

## Deployment Methods

### Method 1: Full Automated Deployment (Recommended)

**On VPS directly:**
```bash
# Clone repository
cd /opt
sudo git clone https://github.com/aishikumar91/FRONTENDOPENMRSBAHMNI healfast-usa
cd healfast-usa

# Run deployment script
sudo bash deploy-healfast-production.sh
```

**From local machine (build locally, deploy to VPS):**
```bash
# In repository root
bash deploy-healfast-production.sh --deploy-to 69.30.247.92
```

### Method 2: Docker Compose Deployment

```bash
# On VPS
cd /opt/healfast-usa

# Create .env file
cp .env.production .env
nano .env  # Edit BACKEND_BASE_URL and other settings

# Build and start
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d

# Configure Nginx manually (see Nginx section)
```

### Method 3: Manual Step-by-Step Deployment

See `MANUAL_DEPLOYMENT.md` for detailed manual deployment steps.

---

## Post-Deployment Verification

### 1. Container Health Check
```bash
# Check container status
docker ps | grep healfast-usa-apps

# Check container logs
docker logs healfast-usa-apps

# Check health endpoint
curl http://localhost:8091/health.json
```

Expected output:
```json
{"status":"healthy","app":"healfast-usa","version":"1.1.0"}
```

### 2. Nginx Verification
```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx status
sudo systemctl status nginx

# Test HTTP to HTTPS redirect
curl -I http://clinic.healfastusa.org
# Should return 301 redirect to HTTPS
```

### 3. SSL Certificate Verification
```bash
# Check certificate status
sudo certbot certificates

# Test SSL
curl -I https://clinic.healfastusa.org

# Check SSL grade (external)
# Visit: https://www.ssllabs.com/ssltest/
```

### 4. Application Verification
- [ ] Visit https://clinic.healfastusa.org
- [ ] Verify landing page loads
- [ ] Navigate to https://clinic.healfastusa.org/bahmni/home/
- [ ] Test login functionality (requires backend)
- [ ] Verify all static assets load (check browser console)
- [ ] Test on multiple browsers (Chrome, Firefox, Safari)
- [ ] Test on mobile devices

### 5. Security Verification
```bash
# Check firewall status
sudo ufw status

# Check Fail2Ban status
sudo fail2ban-client status

# Verify security headers
curl -I https://clinic.healfastusa.org | grep -E "X-Frame-Options|X-Content-Type|Strict-Transport"
```

### 6. Performance Verification
```bash
# Check response time
time curl -I https://clinic.healfastusa.org

# Check resource usage
docker stats healfast-usa-apps --no-stream
```

---

## Rollback Strategy

### Quick Rollback (Docker Image)

```bash
# List available images
docker images | grep healfast-usa-apps

# Tag current image as backup
docker tag healfast-usa-apps:latest healfast-usa-apps:backup-$(date +%Y%m%d)

# Rollback to previous image
docker-compose -f docker-compose.production.yml down
docker tag healfast-usa-apps:backup-YYYYMMDD healfast-usa-apps:latest
docker-compose -f docker-compose.production.yml up -d
```

### Full Rollback (Code Level)

```bash
# On VPS
cd /opt/healfast-usa

# Create backup of current deployment
sudo tar -czf /opt/healfast-backup-$(date +%Y%m%d-%H%M%S).tar.gz /opt/healfast-usa

# Restore from Git
git fetch origin
git checkout <previous-commit-hash>

# Rebuild and deploy
sudo bash deploy-healfast-production.sh
```

### DNS Rollback

If critical issues occur:
1. Update DNS A records to point to old server IP
2. Wait for DNS propagation (5-30 minutes with low TTL)
3. Verify old system is operational

---

## Operational Procedures

### Starting the System
```bash
sudo bash deploy-healfast-production.sh --start
```

### Stopping the System
```bash
sudo bash deploy-healfast-production.sh --stop
```

### Restarting the System
```bash
sudo bash deploy-healfast-production.sh --restart
```

### Viewing Logs
```bash
# Container logs
docker logs -f healfast-usa-apps

# Nginx access logs
sudo tail -f /var/log/nginx/healfast-clinic-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/healfast-clinic-error.log

# System logs
journalctl -u healfast-usa.service -f
```

### Updating the Application
```bash
# Pull latest code
cd /opt/healfast-usa
git pull origin master

# Rebuild and restart
docker-compose -f docker-compose.production.yml up -d --build
```

### Updating SSL Certificates
```bash
# Manual renewal
sudo certbot renew

# Test renewal (dry run)
sudo certbot renew --dry-run

# Auto-renewal is enabled via certbot.timer
sudo systemctl status certbot.timer
```

---

## Monitoring & Maintenance

### Daily Monitoring

**Automated Health Checks:**
```bash
# Add to crontab (crontab -e)
*/5 * * * * curl -f http://localhost:8091/health.json || echo "HealsFast USA health check failed" | mail -s "Alert" admin@healfastusa.org
```

**Manual Checks:**
```bash
# Check container status
docker ps

# Check resource usage
docker stats healfast-usa-apps --no-stream

# Check disk space
df -h

# Check memory usage
free -h

# Check system load
uptime
```

### Weekly Maintenance

- [ ] Review Nginx access logs for unusual patterns
- [ ] Check SSL certificate expiration: `sudo certbot certificates`
- [ ] Review Fail2Ban logs: `sudo fail2ban-client status`
- [ ] Check for system updates: `sudo apt update && sudo apt list --upgradable`
- [ ] Verify backup integrity (if backups configured)

### Monthly Maintenance

- [ ] Update system packages: `sudo apt update && sudo apt upgrade`
- [ ] Review and rotate logs
- [ ] Test disaster recovery procedures
- [ ] Review and update firewall rules if needed
- [ ] Performance optimization review

### Backup Procedures

**Manual Backup:**
```bash
# Backup entire application
sudo tar -czf /backup/healfast-$(date +%Y%m%d).tar.gz /opt/healfast-usa

# Backup Docker image
docker save healfast-usa-apps:latest | gzip > /backup/healfast-image-$(date +%Y%m%d).tar.gz

# Backup Nginx configuration
sudo tar -czf /backup/nginx-config-$(date +%Y%m%d).tar.gz /etc/nginx/sites-available/healfast-usa

# Backup SSL certificates
sudo tar -czf /backup/ssl-certs-$(date +%Y%m%d).tar.gz /etc/letsencrypt
```

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs healfast-usa-apps
docker-compose -f docker-compose.production.yml logs
```

**Common issues:**
- Port 8091 already in use: `sudo lsof -i :8091`
- Insufficient resources: `docker stats`
- Build errors: Check build logs

**Solution:**
```bash
# Stop conflicting services
sudo docker stop $(sudo docker ps -q)

# Rebuild from scratch
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d
```

### SSL Certificate Issues

**Certificate not obtained:**
```bash
# Verify DNS
dig clinic.healfastusa.org

# Check Nginx configuration
sudo nginx -t

# Manually obtain certificate
sudo certbot --nginx -d clinic.healfastusa.org -d admin.healfastusa.org -d staff.healfastusa.org
```

### Application Not Loading

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

**Check container:**
```bash
docker ps
curl http://localhost:8091/health.json
```

### Backend Connection Issues

**Verify backend URL in environment:**
```bash
docker exec healfast-usa-apps env | grep BACKEND
```

**Update backend URL:**
```bash
# Edit .env file
nano /opt/healfast-usa/.env

# Update BACKEND_BASE_URL
# Restart container
docker-compose -f docker-compose.production.yml restart
```

---

## Security Hardening

### SSH Hardening

**Disable password authentication:**
```bash
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

### Fail2Ban Configuration

**Check banned IPs:**
```bash
sudo fail2ban-client status nginx-http-auth
```

### Regular Security Updates

```bash
# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Emergency Contacts

- **System Administrator:** administrator@healfastusa.org
- **Technical Support:** support@healfastusa.org

---

**Last Updated:** 2026-02-11
**Version:** 1.1.0
**Maintained by:** HealsFast USA DevOps Team
