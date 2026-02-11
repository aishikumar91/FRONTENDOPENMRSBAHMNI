# HealsFast USA - Rollback Strategy

## Overview

This document outlines the rollback procedures for HealsFast USA production deployment. Rollback may be necessary in case of:
- Critical bugs discovered post-deployment
- Performance degradation
- Security vulnerabilities
- Integration issues with backend
- User-facing errors

**Recovery Time Objective (RTO):** 15 minutes  
**Recovery Point Objective (RPO):** Last successful deployment

---

## Rollback Decision Matrix

| Severity | Issue Type | Action | Rollback Required |
|----------|-----------|--------|-------------------|
| **Critical** | Application down, data loss risk | Immediate rollback | Yes |
| **High** | Major functionality broken, security issue | Rollback within 30 min | Yes |
| **Medium** | Minor functionality broken, performance degraded | Evaluate, may rollback | Maybe |
| **Low** | UI glitches, non-critical bugs | Fix forward | No |

---

## Pre-Rollback Checklist

Before initiating rollback:
- [ ] Confirm the issue is deployment-related (not backend/infrastructure)
- [ ] Document the issue (screenshots, logs, error messages)
- [ ] Notify stakeholders of impending rollback
- [ ] Verify backup/previous version availability
- [ ] Ensure team is ready to execute rollback

---

## Rollback Methods

### Method 1: Docker Image Rollback (Fastest - 5 minutes)

**Use when:** Recent deployment, Docker image still available

**Prerequisites:**
- Previous Docker image tagged and available
- No database schema changes

**Steps:**

```bash
# 1. SSH to VPS
ssh administrator@69.30.247.92

# 2. Navigate to application directory
cd /opt/healfast-usa

# 3. List available Docker images
docker images | grep healfast-usa-apps

# 4. Stop current container
docker-compose -f docker-compose.production.yml down

# 5. Tag previous image as latest
docker tag healfast-usa-apps:backup-YYYYMMDD healfast-usa-apps:latest

# 6. Start container with previous image
docker-compose -f docker-compose.production.yml up -d

# 7. Verify health
curl http://localhost:8091/health.json

# 8. Check logs
docker logs -f healfast-usa-apps

# 9. Test application
curl -I https://clinic.healfastusa.org
```

**Verification:**
- [ ] Container running: `docker ps | grep healfast-usa-apps`
- [ ] Health check passing
- [ ] Application accessible via HTTPS
- [ ] No errors in logs

**Rollback Time:** ~5 minutes

---

### Method 2: Git Commit Rollback (Medium - 10-15 minutes)

**Use when:** Need to rollback to specific code version, rebuild required

**Prerequisites:**
- Git repository accessible
- Previous commit hash known
- Build environment functional

**Steps:**

```bash
# 1. SSH to VPS
ssh administrator@69.30.247.92

# 2. Navigate to application directory
cd /opt/healfast-usa

# 3. Create backup of current state
sudo tar -czf /backup/healfast-rollback-$(date +%Y%m%d-%H%M%S).tar.gz /opt/healfast-usa

# 4. View commit history
git log --oneline -10

# 5. Checkout previous commit
git fetch origin
git checkout <previous-commit-hash>

# 6. Rebuild application
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# 7. Verify deployment
curl http://localhost:8091/health.json
docker logs -f healfast-usa-apps
```

**Verification:**
- [ ] Correct commit checked out: `git log -1`
- [ ] Build successful (no errors)
- [ ] Container running
- [ ] Application functional

**Rollback Time:** ~10-15 minutes

---

### Method 3: Full System Restore (Slowest - 20-30 minutes)

**Use when:** Complete system failure, corruption, or major infrastructure issue

**Prerequisites:**
- Full system backup available
- Backup verified and tested

**Steps:**

```bash
# 1. SSH to VPS
ssh administrator@69.30.247.92

# 2. Stop all services
sudo systemctl stop nginx
docker-compose -f /opt/healfast-usa/docker-compose.production.yml down

# 3. Restore from backup
cd /opt
sudo rm -rf healfast-usa
sudo tar -xzf /backup/healfast-YYYYMMDD.tar.gz

# 4. Restore Nginx configuration
sudo tar -xzf /backup/nginx-config-YYYYMMDD.tar.gz -C /

# 5. Restore SSL certificates (if needed)
sudo tar -xzf /backup/ssl-certs-YYYYMMDD.tar.gz -C /

# 6. Restart services
cd /opt/healfast-usa
docker-compose -f docker-compose.production.yml up -d
sudo systemctl start nginx

# 7. Verify all services
sudo systemctl status nginx
docker ps
curl http://localhost:8091/health.json
```

**Verification:**
- [ ] All files restored
- [ ] Nginx running
- [ ] Docker container running
- [ ] SSL certificates valid
- [ ] Application accessible

**Rollback Time:** ~20-30 minutes

---

## Post-Rollback Procedures

### Immediate Actions (Within 5 minutes)

1. **Verify Application Functionality**
   ```bash
   # Health check
   curl http://localhost:8091/health.json
   
   # HTTPS access
   curl -I https://clinic.healfastusa.org
   
   # Check all domains
   for domain in clinic.healfastusa.org admin.healfastusa.org staff.healfastusa.org; do
       echo "Testing $domain..."
       curl -I https://$domain
   done
   ```

2. **Monitor Logs**
   ```bash
   # Container logs
   docker logs -f healfast-usa-apps
   
   # Nginx logs
   sudo tail -f /var/log/nginx/healfast-clinic-access.log
   sudo tail -f /var/log/nginx/healfast-clinic-error.log
   ```

3. **Notify Stakeholders**
   - Send notification that rollback is complete
   - Provide status update
   - Estimate time for fix

### Short-term Actions (Within 1 hour)

4. **Document the Incident**
   - What went wrong
   - When it was detected
   - Rollback method used
   - Time to recover
   - Impact on users

5. **Root Cause Analysis**
   - Identify what caused the issue
   - Review deployment process
   - Identify gaps in testing

6. **Create Fix Plan**
   - Document required fixes
   - Create test plan
   - Schedule re-deployment

### Long-term Actions (Within 24 hours)

7. **Improve Deployment Process**
   - Update deployment checklist
   - Add additional tests
   - Improve monitoring

8. **Update Documentation**
   - Document lessons learned
   - Update rollback procedures if needed
   - Share knowledge with team

---

## Emergency Rollback Contacts

| Role | Name | Contact | Availability |
|------|------|---------|--------------|
| DevOps Lead | TBD | TBD | 24/7 |
| System Admin | administrator | TBD | 24/7 |
| Technical Lead | TBD | TBD | Business hours |
| On-call Engineer | TBD | TBD | 24/7 |

---

## Rollback Testing

**Frequency:** Quarterly

**Test Procedure:**
1. Deploy to staging environment
2. Simulate failure scenario
3. Execute rollback procedure
4. Measure rollback time
5. Verify application functionality
6. Document results and improvements

---

**Last Updated:** 2026-02-11  
**Version:** 1.0  
**Next Review Date:** 2026-05-11

