---
sidebar_position: 1
---

# Getting Started with Veracity

Welcome to **Veracity** - A modern server management platform built with Ruby on Rails and SaltStack.

> ⚠️ **ALPHA SOFTWARE** - Version 0.0.1-a is in early development. Features and APIs may change.

## Quick Start

Veracity provides a one-line installation script that handles all dependencies and configuration automatically.

### Prerequisites

Before installing Veracity, ensure your system meets these requirements:

- **Operating System**: Ubuntu 20.04/22.04/24.04 LTS or Debian 11/12
- **CPU**: 2 cores minimum
- **RAM**: 2GB minimum (4GB recommended)
- **Disk**: 20GB free space
- **Network**: Static IP address or FQDN
- **Access**: Root or sudo privileges

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/Pwoodlock/veracity-/main/install.sh | sudo bash
```

The installer will:
1. Detect your operating system
2. Collect configuration (domain, admin credentials, etc.)
3. Install all required dependencies
4. Configure services (PostgreSQL, Redis, SaltStack, Caddy)
5. Deploy the Veracity application
6. Set up systemd services and firewall

**Installation time**: Approximately 10-15 minutes

### Manual Installation

For more control over the installation process:

```bash
# Clone the repository
git clone https://github.com/Pwoodlock/veracity-.git
cd veracity-

# Run the installer
sudo ./install.sh
```

### What Gets Installed

| Component | Version | Purpose |
|-----------|---------|---------|
| Ruby | 3.3.6 | Application runtime (via Mise version manager) |
| Rails | 8.1.1 | Web framework |
| Node.js | 24 LTS | Asset compilation |
| PostgreSQL | 14+ | Database |
| Redis | 7+ | Cache & job queue |
| SaltStack | 3007.8 | Infrastructure automation |
| Python | 3.8+ | Salt integrations |
| Caddy | Latest | Web server with auto-HTTPS |
| Gotify | Latest | Push notifications (binary) |

### After Installation

Once installation completes, you'll receive:

1. **Web Interface URL**: `https://your-domain.com` or `http://your-ip`
2. **Admin Credentials**: Saved in `/tmp/veracity-install-credentials-*.txt`
3. **Service Status**: All services running and enabled

### Next Steps

After installation:

1. Access the web interface with your admin credentials
2. Enable two-factor authentication (2FA) for security
3. Configure your organization settings in Admin → Settings
4. Install Salt minions on servers you want to manage
5. Start managing your infrastructure!

## Need Help?

- **Documentation**: https://pwoodlock.github.io/veracity-/
- **Issues**: https://github.com/Pwoodlock/veracity-/issues
- **Discussions**: https://github.com/Pwoodlock/veracity-/discussions
