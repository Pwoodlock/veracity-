<div align="center">

![Veracity Logo](docs/static/img/logo.svg)

[![Veracity Version](https://img.shields.io/badge/Veracity-0.0.1--a-blue.svg)](https://github.com/Pwoodlock/veracity-)
[![Ruby Version](https://img.shields.io/badge/Ruby-3.3.6-red.svg)](https://www.ruby-lang.org/)
[![Rails Version](https://img.shields.io/badge/Rails-8.1.1-red.svg)](https://rubyonrails.org/)
[![SaltStack Version](https://img.shields.io/badge/SaltStack-3007.8-00c7b7.svg)](https://saltproject.io/)
[![Node.js Version](https://img.shields.io/badge/Node.js-24_LTS-339933.svg)](https://nodejs.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)


**[📚 Documentation](https://pwoodlock.github.io/veracity-/)** | **[🚀 Quick Start Guide](https://pwoodlock.github.io/veracity-/docs/intro)**

</div>

# Veracity

**Version:** 0.0.1-alpha

> ⚠️ **ALPHA SOFTWARE** - This project is in early development. Features and APIs may change.

## System Requirements

### Supported Operating Systems
- **Ubuntu** 20.04 LTS, 22.04 LTS, 24.04 LTS
- **Debian** 11 (Bullseye), 12 (Bookworm)

> 📋 **Note**: RHEL-based distributions (Rocky Linux, AlmaLinux, RHEL) support is planned for future releases.

### Software Stack
| Component | Version | Purpose |
|-----------|---------|---------|
| **Ruby** | 3.3.6 | Application runtime (via Mise version manager) |
| **Rails** | 8.1.1 | Web application framework |
| **Node.js** | 24 LTS | JavaScript runtime for asset compilation |
| **PostgreSQL** | 14+ | Primary database |
| **Redis** | 7+ | Cache & background job queue |
| **SaltStack** | 3007.8 | Infrastructure automation & minion management |
| **Python** | 3.8+ | Salt integrations & API clients |
| **Caddy** | Latest | Web server with automatic HTTPS |

### Hardware Requirements (Minimum)
- **CPU**: 2 cores
- **RAM**: 2GB (4GB recommended)
- **Disk**: 20GB free space
- **Network**: Static IP or FQDN for production deployment

### Additional Features
- **Gotify** (Binary) - Push notifications with path-based reverse proxy
- **BorgBackup** - Server backup & cloning
- **CVE Scanner** - Vulnerability monitoring
- **API Integrations**: Hetzner Cloud, Proxmox VE

---

