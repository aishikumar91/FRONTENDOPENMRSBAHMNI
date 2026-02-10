# HealFast USA – Deployment on Ubuntu 22 LTS VPS

This app is branded as **HealFast USA**. Deploy to Ubuntu 22 LTS at **administrator@69.30.247.92** with SSL for **clinic.healfastusa.org**, **admin.healfastusa.org**, and **staff.healfastusa.org**. Server timezone is **Africa/Lagos**.

## Single script (recommended)

One script installs dependencies, builds the app, runs it in Docker, sets timezone to **Africa/Lagos**, and configures **Nginx + Let's Encrypt SSL** for the three domains.

### Prerequisites

- DNS: Point **clinic.healfastusa.org**, **admin.healfastusa.org**, and **staff.healfastusa.org** to **69.30.247.92** (A records) before running so Certbot can issue certificates.

### Option 1: Run on the VPS

1. Copy the repo to the server:
   ```bash
   rsync -avz --exclude node_modules --exclude ui/node_modules --exclude micro-frontends/node_modules \
     ./openmrs-module-bahmniapps/ administrator@69.30.247.92:/opt/healfast-usa/
   ```
2. SSH and run the script:
   ```bash
   ssh administrator@69.30.247.92
   sudo bash /opt/healfast-usa/run-healfast-on-vps.sh
   ```

### Option 2: Build locally and deploy to VPS

From your machine (Node and Yarn installed), in the repo root:

```bash
bash run-healfast-on-vps.sh --deploy-to 69.30.247.92
```

This builds the app, rsyncs to **administrator@69.30.247.92:/opt/healfast-usa/**, then runs the script on the VPS (container + Nginx/SSL). Use **administrator**, not root.

### After setup

- **HTTPS:** https://clinic.healfastusa.org, https://admin.healfastusa.org, https://staff.healfastusa.org  
- **Timezone:** Africa/Lagos (set by script)  
- **App container:** `sudo docker stop healfast-usa-apps` / `sudo docker logs -f healfast-usa-apps`  
- **SSL renewal:** Automatic via `certbot.timer`; or manually: `sudo certbot renew`

---

## Logo files

- **HealFast logos:** `ui/app/images/healfastLogoFull.png` and `ui/app/images/healfastLogo.png`. Replace with your assets if needed; the single script uses whatever is in the repo.

---

## Manual build (without script)

From repo root:

1. **Micro-frontends:** `cd micro-frontends && yarn install && yarn build`
2. **UI:** `cd ui && yarn install && yarn ci`
3. **Docker:** `docker build -f package/docker/Dockerfile -t healfast-usa-apps .`

---

## Backend

This frontend expects the Bahmni/OpenMRS backend to be running and reachable. Configure the app’s API base URL for your environment (e.g. same VPS or another host).

---

## Summary

| Item        | Value |
|------------|--------|
| Server     | administrator@69.30.247.92 |
| Timezone   | Africa/Lagos |
| SSL domains| clinic.healfastusa.org, admin.healfastusa.org, staff.healfastusa.org |
| Script     | `run-healfast-on-vps.sh` |
