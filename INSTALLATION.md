# Veracity Installation Guide

Complete installation guide for Veracity Server Manager - a comprehensive infrastructure management platform powered by SaltStack.

## Quick Start

For a fully automated installation on a fresh Ubuntu 22.04/24.04, Debian 11/12, or Rocky Linux 9 server:

```bash
curl -sSL https://raw.githubusercontent.com/Pwoodlock/veracity/main/install.sh | sudo bash
```

**Or clone and run locally:**

```bash
git clone https://github.com/Pwoodlock/veracity.git
cd veracity
sudo ./install.sh
```

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 22.04/24.04, Debian 11/12, or Rocky Linux 9
- **CPU**: 2 cores
- **RAM**: 2GB minimum (4GB recommended)
- **Disk**: 10GB free space
- **Network**: Internet connectivity for package downloads

### Recommended for Production
- **CPU**: 4+ cores
- **RAM**: 4GB+ (8GB for larger deployments)
- **Disk**: 20GB+ SSD storage
- **Network**: Static IP or domain with DNS configured

## What Gets Installed

The installer sets up a complete, production-ready infrastructure management system:

### Core Services
- **PostgreSQL 14+** - Primary database
- **Redis 7+** - Caching and job queues
- **SaltStack Master & API** - Minion management and automation
- **Ruby 3.3.5** (via rbenv) - Application runtime
- **Node.js 18 LTS** - Asset compilation
- **Caddy v2** - Reverse proxy with automatic HTTPS

### Application Components
- **Puma** - Rails application server
- **Sidekiq** - Background job processing
- **Systemd services** - Auto-start and monitoring
- **UFW Firewall** - Security rules

### Integrated Features (All Installed)
- **Gotify** - Push notifications (Docker-based)
- **CVE Monitoring** - Automatic vulnerability scanning (Python venv)
- **Proxmox API** - Virtual machine management
- **Hetzner Cloud API** - Cloud server management
- **OAuth2/Zitadel** - SSO authentication ready

## Installation Process

### 1. Pre-Installation

Before running the installer, ensure:

- You have root/sudo access
- Server has a fresh OS installation (recommended)
- DNS is configured (for HTTPS with Let's Encrypt)
- Ports 80, 443, 4505, 4506 are accessible

### 2. Interactive Prompts

The installer will ask for:

**Required:**
- Domain or IP address (e.g., `sm.example.com`)
- Enable HTTPS? (yes/no)
- Admin email address
- Admin password (or auto-generate)
- Database username (default: `servermanager`)
- Server timezone (default: UTC)

**All Features Installed Automatically:**
- Gotify push notifications (configure via UI)
- CVE vulnerability scanning (active)
- Proxmox API support (add tokens via UI)
- Hetzner Cloud API support (add tokens via UI)
- OAuth2/Zitadel SSO (configure via UI)

### 3. Installation Steps

The installer performs these steps automatically:

1. ✓ System prerequisites check
2. ✓ Install PostgreSQL and create database
3. ✓ Install and configure Redis
4. ✓ Install Salt Master and Salt API
5. ✓ Install Ruby 3.3.5 via rbenv
6. ✓ Install Node.js 18 and Yarn
7. ✓ Install Caddy and configure automatic HTTPS
8. ✓ Install Gotify push notification server (Docker)
9. ✓ Install CVE monitoring with Python venv
10. ✓ Clone application and install dependencies
11. ✓ Run database migrations and seed data
12. ✓ Precompile assets
13. ✓ Create admin user
14. ✓ Install systemd services
15. ✓ Configure firewall
16. ✓ Run health checks

**Estimated time: 25-35 minutes** (depends on internet speed and server specs)

### 4. Post-Installation

After installation completes:

1. **Access Dashboard**: Navigate to `https://your-domain.com`
2. **Login**: Use the admin email and password
3. **Enable 2FA**: Go to Settings → Security
4. **Configure Gotify**: Go to Settings → Notifications to add Gotify app token
5. **Configure Proxmox**: Go to Settings → Proxmox to add API tokens
6. **Configure Hetzner**: Go to Settings → Hetzner to add API tokens
7. **Configure OAuth/SSO**: Go to Settings → Authentication (if needed)
8. **Review CVE Scans**: Check Settings → Vulnerability Monitoring
9. **Install Minions**: Run on servers you want to manage:
   ```bash
   curl -sSL https://your-domain.com/install/minion.sh | sudo bash
   ```
10. **Accept Minion Keys**: Go to Onboarding page and accept keys

## File Locations

```
/opt/server-manager/              # Application directory
├── app/                          # Rails application code
├── config/                       # Configuration files
├── log/                          # Application logs
├── .env.production               # Environment variables
├── public/                       # Static assets
├── cve_venv/                     # Python virtual environment for CVE monitoring
└── bin/cve_python                # Python wrapper script

/home/deploy/                     # Deploy user home
└── .rbenv/                       # Ruby installation

/var/log/veracity-install/        # Installation logs
/root/veracity-install-credentials.txt  # Saved credentials

/var/lib/gotify/                  # Gotify data directory

/etc/systemd/system/
├── server-manager.service        # Puma service
└── server-manager-sidekiq.service  # Sidekiq service

/etc/caddy/Caddyfile              # Caddy configuration
/srv/salt/                        # Salt states
/srv/pillar/                      # Salt pillars
```

## Managing Services

### View Service Status
```bash
systemctl status server-manager
systemctl status server-manager-sidekiq
systemctl status caddy
systemctl status postgresql
systemctl status redis
systemctl status salt-master
systemctl status salt-api
systemctl status docker
docker ps  # View running containers (Gotify)
```

### Restart Services
```bash
systemctl restart server-manager
systemctl restart server-manager-sidekiq
```

### View Logs
```bash
# Application logs
tail -f /opt/server-manager/log/production.log

# Puma logs
tail -f /opt/server-manager/log/puma.log

# Sidekiq logs
tail -f /opt/server-manager/log/sidekiq.log

# System logs
journalctl -u server-manager -f
journalctl -u server-manager-sidekiq -f
```

## Troubleshooting

### Installation Failed

Check installation logs:
```bash
tail -n 100 /var/log/veracity-install/install-*.log
```

### Services Not Starting

Check service status and logs:
```bash
systemctl status server-manager
journalctl -u server-manager -n 50 --no-pager
```

### Database Connection Issues

Test database connectivity:
```bash
sudo -u postgres psql -d server_manager_production
```

### Rails Console Access

For debugging:
```bash
cd /opt/server-manager
sudo -u deploy bash -lc "RAILS_ENV=production bundle exec rails console"
```

### Reset Admin Password

```bash
cd /opt/server-manager
sudo -u deploy bash -lc "RAILS_ENV=production bundle exec rails runner \"
user = User.find_by(email: 'admin@example.com')
user.password = 'new-secure-password'
user.password_confirmation = 'new-secure-password'
user.save!
\""
```

## Firewall Configuration

Default UFW rules:
```
22/tcp   - SSH
80/tcp   - HTTP
443/tcp  - HTTPS
4505/tcp - Salt Publisher
4506/tcp - Salt Request Server
```

### Add Custom Rules
```bash
ufw allow 8080/tcp comment "Custom service"
ufw reload
```

## Upgrading

### Automated Update (Recommended)

To update Veracity to the latest version from GitHub, use the included update script:

```bash
sudo /opt/server-manager/scripts/update.sh
```

This automated script will:
1. Create a backup of your current installation
2. Pull the latest code from GitHub (`main` branch)
3. Update Ruby gems (exact versions from `Gemfile.lock`)
4. Update Node packages (exact versions from `yarn.lock`)
5. Run database migrations
6. Precompile assets
7. Restart services
8. Run health checks

**Version Control:**
- All dependency versions are controlled by `Gemfile.lock` and `yarn.lock` in the repository
- The update script uses `--deployment` and `--frozen-lockfile` flags to ensure exact version matching
- You'll get the same tested versions as the developer

**Backup Location:** `/opt/backups/veracity-YYYYMMDD-HHMMSS/`

### Manual Update

If you prefer to update manually:

```bash
# Stop services
sudo systemctl stop server-manager server-manager-sidekiq

# Pull latest code
cd /opt/server-manager
sudo -u deploy git pull origin main

# Update dependencies (uses exact versions from lock files)
sudo -u deploy bash -lc "cd /opt/server-manager && bundle install --deployment"
sudo -u deploy bash -lc "cd /opt/server-manager && yarn install --frozen-lockfile"

# Run migrations
sudo -u deploy bash -lc "cd /opt/server-manager && RAILS_ENV=production bundle exec rails db:migrate"

# Precompile assets
sudo -u deploy bash -lc "cd /opt/server-manager && RAILS_ENV=production bundle exec rails assets:precompile"

# Start services
sudo systemctl start server-manager server-manager-sidekiq

# Check status
sudo systemctl status server-manager server-manager-sidekiq
```

### Checking for Updates

To see if updates are available without installing:

```bash
cd /opt/server-manager
sudo -u deploy git fetch origin main
sudo -u deploy git log HEAD..origin/main --oneline
```

### Rolling Back an Update

If an update causes issues, you can rollback to a previous version:

```bash
# Find backup directory
ls -la /opt/backups/

# Stop services
sudo systemctl stop server-manager server-manager-sidekiq

# Restore from backup
sudo cp -r /opt/backups/veracity-YYYYMMDD-HHMMSS/server-manager /opt/

# Start services
sudo systemctl start server-manager server-manager-sidekiq
```

## Uninstalling

To completely remove Veracity:

```bash
# Stop services
systemctl stop server-manager server-manager-sidekiq caddy salt-api salt-master

# Remove application
rm -rf /opt/server-manager

# Remove services
rm /etc/systemd/system/server-manager*.service
systemctl daemon-reload

# Optionally remove dependencies
apt-get remove --purge postgresql redis-server salt-master salt-api caddy
userdel -r deploy
```

## Security Best Practices

1. **Enable 2FA** for all admin accounts
2. **Change default passwords** immediately after installation
3. **Keep system updated**: `apt update && apt upgrade` (Ubuntu/Debian)
4. **Configure backup strategy** for database and application data
5. **Monitor logs regularly** for suspicious activity
6. **Use strong passwords** for all services
7. **Restrict SSH access** to specific IPs if possible
8. **Enable fail2ban** for additional brute-force protection

## Support & Documentation

- **Documentation**: https://github.com/Pwoodlock/veracity/wiki
- **Issues**: https://github.com/Pwoodlock/veracity/issues
- **Discussions**: https://github.com/Pwoodlock/veracity/discussions
- **Email**: support@veracity.io (if configured)

## License

Veracity is open-source software licensed under the MIT License.

---

**Need help?** Open an issue on GitHub or check the troubleshooting section above.
