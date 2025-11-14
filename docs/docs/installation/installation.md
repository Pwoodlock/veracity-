---
sidebar_position: 1
---

# Installation Guide

Complete guide for installing Veracity on your server.

## System Requirements

### Supported Operating Systems

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

### Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 2GB | 4GB+ |
| Disk | 20GB | 50GB+ |
| Network | 100 Mbps | 1 Gbps |

## Installation Methods

### Method 1: One-Line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/Pwoodlock/veracity-/main/install.sh | sudo bash
```

### Method 2: Clone and Install

```bash
git clone https://github.com/Pwoodlock/veracity-.git
cd veracity-
sudo ./install.sh
```

## Installation Steps

### 1. Collect Configuration

The installer will prompt you for:

- **Domain/IP Address**: Your server's FQDN or IP address
- **HTTPS Setup**: Enable automatic Let's Encrypt certificates
- **Admin Email**: Administrator email address
- **Admin Password**: Auto-generated secure password (or custom)
- **Gotify Domain**: Subdomain for push notifications

### 2. Automated Installation

The installer performs these steps automatically:

```bash
# System packages update
✓ Update package lists

# Core dependencies
✓ Install PostgreSQL 14+
✓ Install Redis 7+
✓ Install SaltStack 3007.8
✓ Install Ruby 3.4.7 (Fullstaq precompiled)
✓ Install Node.js 24 LTS
✓ Install Caddy web server

# Optional features
✓ Install Gotify (Docker)
✓ Install BorgBackup
✓ Install Python integrations (Hetzner, Proxmox, CVE)

# Application setup
✓ Create deploy user
✓ Clone application repository
✓ Install dependencies (bundle, yarn)
✓ Create database and run migrations
✓ Compile assets
✓ Configure systemd services
✓ Setup firewall rules
```

### 3. Post-Installation

After successful installation:

```bash
# View credentials
cat /tmp/veracity-install-credentials-*.txt

# Check service status
systemctl status server-manager
systemctl status server-manager-sidekiq

# View logs
journalctl -u server-manager -f
```

## Installation Options

### Resume Interrupted Installation

If installation was interrupted:

```bash
sudo ./install.sh --resume
```

### Rollback Installation

To rollback changes if installation fails:

```bash
sudo ./install.sh --rollback
```

## Firewall Configuration

The installer automatically configures firewall rules:

| Service | Port | Protocol |
|---------|------|----------|
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| SSH | 22 | TCP |
| Salt Master | 4505-4506 | TCP |
| Gotify | 8080 | TCP |

## Troubleshooting

### Check Installation Logs

```bash
tail -f /var/log/veracity-install/install-*.log
```

### Common Issues

**PostgreSQL Connection Error**
```bash
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT 1"
```

**Ruby Not Found**
```bash
sudo -u deploy bash -lc "ruby -v"
```

**Service Won't Start**
```bash
journalctl -u server-manager -n 50 --no-pager
```

## Next Steps

After successful installation:

1. [Initial Configuration](./configuration.md)
2. [Install Salt Minions](./minions.md)
3. [Security Hardening](./security.md)
4. [Backup Configuration](./backup.md)
