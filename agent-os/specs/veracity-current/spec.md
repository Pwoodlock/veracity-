# Veracity Infrastructure Management Platform - Technical Specification

## Project Overview

**Project Name:** Veracity
**Version:** 0.0.1-alpha
**Status:** Active Development
**Repository:** https://github.com/Pwoodlock/veracity-

### Executive Summary

Veracity is a comprehensive infrastructure automation and server management platform built on Ruby on Rails 8.1.1, integrating SaltStack for infrastructure orchestration. The platform provides enterprise-grade server management, security monitoring, automated backups, and multi-cloud provider support through a modern web interface.

### Purpose & Goals

**Primary Purpose:**
- Centralized infrastructure management for physical and cloud servers
- Automated security vulnerability monitoring and alerting
- Task automation and scheduled execution
- Multi-cloud provider integration (Hetzner Cloud, Proxmox VE)
- Real-time server metrics and status monitoring

**Business Goals:**
- Reduce manual server management overhead by 80%
- Provide real-time vulnerability detection and alerting
- Enable one-click server provisioning and management
- Centralize backup and disaster recovery operations
- Support hybrid cloud deployments

## Technical Architecture

### Technology Stack

#### Backend Framework
- **Ruby:** 3.3.6 (managed via Mise/rbenv)
- **Rails:** 8.1.1 (latest stable)
- **Application Server:** Puma (5.0+)
- **Background Jobs:** Sidekiq 7.1 with Cron scheduling

#### Database & Storage
- **Primary Database:** PostgreSQL 14+
- **Cache Store:** Redis 7+
- **Queue Backend:** Solid Queue (Rails 8)
- **Cable Backend:** Solid Cable (Rails 8)
- **Cache Backend:** Solid Cache (Rails 8)

#### Infrastructure Automation
- **Orchestration:** SaltStack 3007.8 (Master + API)
- **Configuration:** Salt States & Pillars
- **Event Stream:** WebSocket integration for real-time updates

#### Frontend Technologies
- **Asset Pipeline:** Propshaft (Rails 8 default)
- **JavaScript Framework:** Stimulus.js
- **Real-time:** Turbo Rails (Hotwire)
- **WebSockets:** Action Cable
- **Charts:** Chartkick 5.0
- **Pagination:** Pagy 6.0
- **Components:** ViewComponent 4.0

#### Web Server & Proxy
- **Reverse Proxy:** Caddy v2
- **Features:** Automatic HTTPS, Let's Encrypt integration
- **Protocol:** HTTP/2, HTTP/3 support

#### Authentication & Authorization
- **Authentication:** Devise 4.9
- **Two-Factor Auth:** ROTP 6.3 (TOTP)
- **QR Codes:** RQRCode 2.0
- **Authorization:** Pundit 2.3
- **Rate Limiting:** Rack Attack 6.7
- **OAuth:** OmniAuth OAuth2 1.8 (for future SSO)

#### Security Features
- **Encryption:** attr_encrypted 4.0 (API keys, sensitive data)
- **CVE Scanning:** Python-based vulnerability lookup (venv)
- **Password Security:** bcrypt (Devise default)
- **Session Security:** Encrypted cookies, CSRF protection

#### Integrations

**Cloud Providers:**
- **Hetzner Cloud API** - Server management, snapshots, power control
- **Proxmox VE API** - VM/LXC management, snapshots, operations

**Notification Services:**
- **Gotify** - Self-hosted push notifications (Docker container)
- Path-based reverse proxy: `/gotify`

**Backup Solutions:**
- **BorgBackup** - Deduplicated, encrypted backups
- Remote repository support via SSH

**Monitoring:**
- **CVE Database** - PyVulnerabilityLookup integration
- **Server Metrics** - CPU, Memory, Disk, Network
- **Command History** - Full audit trail

#### Development & Testing Tools
- **Testing Framework:** Minitest (Rails default)
- **Test Data:** FactoryBot 6.4, Faker 3.2
- **HTTP Mocking:** WebMock 3.19
- **Stubbing:** Mocha 2.1
- **Coverage:** SimpleCov 0.22
- **Matchers:** Shoulda Matchers 6.0
- **Security Audit:** Brakeman
- **Code Style:** RuboCop Rails Omakase

#### Deployment
- **Container Orchestration:** Kamal (included but not configured)
- **Web Acceleration:** Thruster
- **Systemd Services:** Puma, Sidekiq
- **Firewall:** UFW with preconfigured rules

### System Architecture

#### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Web Browser                             │
│                    (Users / Admins)                             │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS (443)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Caddy v2                                 │
│                  (Reverse Proxy + HTTPS)                        │
│  ┌──────────────────┬──────────────────┬──────────────────┐   │
│  │ /                │ /cable           │ /gotify          │   │
│  │ (Rails App)      │ (WebSockets)     │ (Notifications)  │   │
└──┴──────────────────┴──────────────────┴──────────────────┴───┘
   │                   │                   │
   ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   Puma Server    │ │  Action Cable    │ │  Gotify Docker   │
│  (Rails 8.1.1)   │ │  (WebSockets)    │ │   Container      │
└────────┬─────────┘ └──────────────────┘ └──────────────────┘
         │
         ├─────────────────────────────────────────┐
         │                                         │
         ▼                                         ▼
┌─────────────────────────┐            ┌─────────────────────────┐
│   PostgreSQL 14+        │            │    Redis 7+             │
│   - Users               │            │    - Cache              │
│   - Servers             │            │    - Sessions           │
│   - Tasks               │            │    - Job Queue          │
│   - CVE Alerts          │            │    - Action Cable       │
│   - Commands            │            └─────────────────────────┘
│   - Backups             │
│   - API Keys            │
└─────────────────────────┘

         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Sidekiq Workers                           │
│  ┌──────────────┬──────────────┬──────────────┬─────────────┐ │
│  │ CVE Scanning │ Task Exec    │ Backup Jobs  │ Metrics     │ │
│  │ (Scheduled)  │ (On-demand)  │ (Scheduled)  │ Collection  │ │
│  └──────────────┴──────────────┴──────────────┴─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌─────────────────────────┐ ┌─────────────────────────────────────┐
│  Python CVE Scanner     │ │    SaltStack Master + API           │
│  (PyVulnerabilityLookup)│ │    - Minion Management              │
│  - venv isolated        │ │    - Command Execution (ports 4505) │
│  - NVD Database         │ │    - Event Stream (port 4506)       │
└─────────────────────────┘ └──────────────┬──────────────────────┘
                                           │ Salt Protocol
                                           ▼
                            ┌──────────────────────────────────────┐
                            │      Managed Servers (Minions)       │
                            │  - Physical Servers                  │
                            │  - Hetzner Cloud Instances           │
                            │  - Proxmox VMs/LXCs                  │
                            └──────────────────────────────────────┘

External APIs:
- Hetzner Cloud API (HTTPS)
- Proxmox VE API (HTTPS)
- BorgBackup Remote Repos (SSH)
```

#### Data Flow

**Server Management Flow:**
1. User initiates command via dashboard
2. Rails controller validates authorization (Pundit)
3. Job queued to Sidekiq
4. Sidekiq worker calls Salt API
5. Salt Master executes command on minion(s)
6. Results stored in Command model
7. Real-time update pushed via Action Cable
8. Dashboard updates automatically (Turbo Streams)

**CVE Monitoring Flow:**
1. CveScanJob triggered by Sidekiq Cron
2. Python script queries vulnerability database
3. Results compared against watchlist criteria
4. VulnerabilityAlert created for matches
5. Gotify notification sent (if configured)
6. Alert displayed on dashboard
7. Admin can acknowledge/resolve/ignore

**Backup Flow:**
1. BorgBackupJob triggered on schedule
2. Configuration retrieved from BackupConfiguration model
3. SSH connection established to remote repo
4. BorgBackup creates encrypted, deduplicated archive
5. Backup history recorded
6. Success/failure notification sent
7. Old backups pruned per retention policy

### Database Schema

#### Core Entities

**Users & Authentication:**
- `users` - Admin users with Devise authentication
  - Email, encrypted password, 2FA settings
  - OTP secret (encrypted), OTP required flag
  - Admin role (future: role-based access)

**Server Management:**
- `servers` - Managed servers
  - Hostname, IP address, OS, kernel version
  - Salt minion_id, grain data (JSON)
  - Status, last seen timestamp
  - Hetzner server_id, API key reference
  - Proxmox vm_id, node, type (qemu/lxc), API key reference
  - Diagnostic fields (connection errors, salt version)

- `groups` - Server grouping for bulk operations
  - Name, description
  - Has many servers (join table)

- `server_metrics` - Time-series metrics
  - Server reference
  - CPU usage, memory usage, disk usage, network I/O
  - Timestamp (indexed for efficient queries)

**Task Automation:**
- `tasks` - Task definitions
  - Name, description, command
  - Target: all/group/specific servers
  - Schedule (cron expression)
  - Enabled/disabled flag
  - Alert thresholds (failure count, duration)

- `task_runs` - Task execution history
  - Task reference, triggered by (user)
  - Status: pending/running/completed/failed
  - Started at, completed at, duration
  - Output, error messages
  - Exit code

- `task_templates` - Predefined task templates
  - Name, description, command template
  - Category (updates, maintenance, custom)

**Security & Compliance:**
- `cve_watchlists` - CVE monitoring configuration
  - Name, description
  - Package filter (regex)
  - Severity threshold (low/medium/high/critical)
  - Schedule (cron expression)
  - Notification settings (Gotify integration)

- `vulnerability_alerts` - Detected vulnerabilities
  - CVE ID, package name, version
  - Severity, CVSS score
  - Description, published date
  - Status: new/acknowledged/resolved/ignored
  - Server references (affected systems)
  - Watchlist reference

- `cve_scan_history` - Scan execution log
  - Watchlist reference
  - Scan started/completed timestamps
  - Alerts generated count
  - Status, error messages

**Backup Management:**
- `backup_configurations` - Borg backup settings
  - Repository URL, SSH key (encrypted)
  - Schedule (cron expression)
  - Retention policy (daily/weekly/monthly counts)
  - Enabled flag

- `backup_history` - Backup execution log
  - Configuration reference
  - Started/completed timestamps
  - Status: success/failed
  - Archive name, size
  - Error messages

**Cloud Provider Integration:**
- `hetzner_api_keys` - Hetzner Cloud credentials
  - Name, API token (encrypted)
  - Enabled flag, last tested timestamp
  - Test results

- `proxmox_api_keys` - Proxmox VE credentials
  - Name, host, port, verify_ssl
  - User, token_name, token_value (encrypted)
  - Enabled flag, last tested timestamp
  - Node list (cached)

**Command & Notification History:**
- `commands` - Salt command execution log
  - Command string, target (minion IDs)
  - User reference (who executed)
  - Status: pending/running/completed/failed
  - Results (JSON), error messages
  - Timestamps

- `notification_history` - Notification delivery log
  - Notification type, recipient
  - Title, message
  - Delivered timestamp
  - Status

**System Configuration:**
- `system_settings` - Key-value application settings
  - Appearance (logo, company name, tagline)
  - Gotify integration (URL, admin credentials)
  - PyVulnerabilityLookup settings (Python path, venv)
  - Email settings
  - Feature flags

#### Indexes & Performance
- `servers.minion_id` - Unique index for Salt lookups
- `server_metrics.created_at` - Index for time-series queries
- `commands.status` - Index for pending/failed command queries
- `vulnerability_alerts.status` - Index for active alerts
- `tasks.schedule` - Index for scheduled task lookups

#### Data Encryption
- API tokens: `attr_encrypted` with application secret
- Passwords: bcrypt (Devise default)
- SSH keys: encrypted at rest
- Session data: encrypted cookies

### API Integrations

#### SaltStack API
- **Endpoint:** http://localhost:8000
- **Authentication:** External auth (PAM)
- **Operations:**
  - List minions (accepted/pending/rejected keys)
  - Accept/reject minion keys
  - Execute commands (cmd.run, state.apply, pkg.install, etc.)
  - Collect grains (system information)
  - Synchronize modules

#### Hetzner Cloud API
- **Endpoint:** https://api.hetzner.cloud/v1
- **Authentication:** Bearer token
- **Operations:**
  - List servers
  - Get server details (status, specs)
  - Power control (start/stop/reboot)
  - Create/list/delete snapshots
  - Get metrics

#### Proxmox VE API
- **Endpoint:** https://proxmox-host:8006/api2/json
- **Authentication:** API token (user@realm!token=secret)
- **Operations:**
  - List VMs/LXCs
  - Get VM/LXC status
  - Power control (start/stop/shutdown/reboot)
  - Create/list/rollback/delete snapshots
  - Get resource usage

#### Gotify API
- **Endpoint:** http://localhost:8080 (internal Docker)
- **Authentication:** Admin credentials or app tokens
- **Operations:**
  - Create applications
  - Send messages
  - List messages
  - Manage users and clients

#### PyVulnerabilityLookup
- **Type:** Python CLI tool (subprocess execution)
- **Location:** `/opt/veracity/app/cve_venv/bin/vulnerability-lookup`
- **Operations:**
  - Search CVEs by package name
  - Filter by severity
  - Return JSON results

### Security Model

#### Authentication
- **Primary:** Devise email/password
- **Two-Factor:** TOTP (Google Authenticator compatible)
- **Session Management:** Encrypted cookies, configurable timeout
- **Password Requirements:** Enforced by Devise (minimum length, complexity)

#### Authorization
- **Framework:** Pundit policy-based authorization
- **Roles:** Admin (current), User (future)
- **Policies:** Controller-level and action-level checks
- **Audit Trail:** User association on commands, tasks, backups

#### Data Protection
- **At Rest:**
  - Database encryption (PostgreSQL native)
  - API tokens encrypted with attr_encrypted
  - SSH keys encrypted
- **In Transit:**
  - HTTPS enforced (Caddy with Let's Encrypt)
  - Salt communication encrypted (ZeroMQ CurveCP)
- **Access Control:**
  - Rate limiting (Rack Attack) - 5 req/sec per IP
  - CSRF protection (Rails default)
  - SQL injection prevention (ActiveRecord parameterized queries)

#### Vulnerability Management
- **Automated Scanning:** CVE watchlists with scheduled scans
- **Alert Workflow:** New → Acknowledged → Resolved/Ignored
- **Notification:** Real-time via Gotify
- **Reporting:** Dashboard widgets, detailed alert views

### Real-Time Features

#### Action Cable Channels
- **DashboardChannel:** Real-time dashboard updates
  - Server status changes
  - Command completion
  - Metric updates
  - Alert notifications

#### Turbo Streams
- Automatic page updates without full reload
- Form submissions with inline validation
- Progressive enhancement (works without JavaScript)

#### WebSocket Architecture
- Solid Cable backend (database-backed)
- Redis pub/sub for multi-server deployments
- Automatic reconnection handling

## Feature Specifications

### 1. Dashboard

**Purpose:** Centralized operations hub with real-time monitoring

**Components:**
- Server status overview (online/offline counts)
- Recent command history (last 10 executions)
- Active vulnerability alerts (unresolved count)
- Quick actions (execute command, sync minions, check updates)
- System metrics charts (CPU, memory, disk usage over time)
- Failed commands widget (with bulk clear action)

**Real-Time Updates:**
- Server status changes
- Command completions
- New vulnerability alerts
- Metric refreshes (every 5 minutes)

### 2. Server Management

**Features:**
- **Server List:** Paginated table with search/filter
  - Columns: Hostname, IP, OS, Status, Last Seen, Actions
  - Bulk actions: Group assignment, command execution

- **Server Detail View:**
  - System information (OS, kernel, architecture)
  - Salt grain data (packages, network interfaces, etc.)
  - Metric charts (CPU, memory, disk, network over 24h/7d/30d)
  - Command history for this server
  - Related alerts

- **Onboarding:**
  - Generate minion installation script
  - Accept/reject pending minion keys
  - Auto-refresh pending keys list

- **Provider Integration:**
  - Hetzner Cloud: Power control, snapshot management
  - Proxmox VE: VM/LXC control, snapshot management
  - Status synchronization with provider APIs

- **Diagnostics:**
  - Connection troubleshooting
  - Salt version compatibility checks
  - Grain refresh
  - Manual sync triggers

### 3. Task Automation

**Features:**
- **Task Creation:**
  - Name, description, command
  - Target selection (all/group/specific servers)
  - Schedule (one-time or cron expression)
  - Alert thresholds (max failures, max duration)

- **Task Templates:**
  - System updates (full)
  - Security updates only
  - Custom commands
  - Template library (expandable)

- **Task Execution:**
  - Manual trigger (execute now)
  - Scheduled execution (Sidekiq Cron)
  - Progress tracking (pending → running → completed/failed)
  - Output capture (stdout/stderr)

- **Task History:**
  - Execution log per task
  - Duration, exit code, output
  - User who triggered (audit trail)
  - Filtering by status, date range

### 4. CVE Monitoring

**Features:**
- **Watchlist Management:**
  - Create watchlists with package filters (regex)
  - Set severity thresholds (low/medium/high/critical)
  - Configure scan schedule (cron)
  - Enable/disable watchlists
  - Test watchlist (immediate scan)

- **Vulnerability Alerts:**
  - Alert list with severity badges
  - Filtering (status, severity, date range)
  - Bulk actions (acknowledge, resolve, ignore)
  - Alert detail view (CVE description, CVSS score, affected servers)
  - Status workflow (new → acknowledged → resolved/ignored)

- **Scanning:**
  - Scheduled scans via Sidekiq Cron
  - On-demand scans (test button)
  - Scan history (timestamps, alert counts)
  - Error logging

- **Notifications:**
  - Gotify push notifications for new alerts
  - Configurable per watchlist
  - Alert summary in messages

### 5. Backup Management

**Features:**
- **Configuration:**
  - BorgBackup repository URL
  - SSH key generation and management
  - Retention policy (daily/weekly/monthly counts)
  - Schedule (cron expression)
  - Enable/disable backups

- **Execution:**
  - Scheduled backups via Sidekiq
  - On-demand backup trigger
  - Progress tracking
  - Output capture

- **History:**
  - Backup log (timestamps, status, size)
  - Error messages
  - Archive names
  - Pruning operations

- **Testing:**
  - Connection test (SSH + Borg)
  - Repository initialization
  - Key permission validation

### 6. Settings & Configuration

**Appearance:**
- Custom logo upload (Active Storage)
- Company name and tagline
- Branding customization

**Integrations:**
- **Hetzner Cloud API Keys:**
  - Add/edit/delete keys
  - Test connection
  - Enable/disable keys
  - Server discovery

- **Proxmox API Keys:**
  - Add/edit/delete keys
  - Test connection
  - Enable/disable keys
  - VM/LXC discovery
  - Node caching

- **Gotify Notifications:**
  - Server URL configuration
  - Admin credentials
  - Connection testing
  - Admin panel link (embedded management)

- **PyVulnerabilityLookup:**
  - Python path configuration
  - Virtual environment location
  - Connection testing
  - Manual scan trigger

**Maintenance:**
- Clear failed commands (bulk delete)
- Clear old commands (retention policy)
- Database health checks
- Cache clearing

**User Management:**
- Admin user list
- Create/edit/delete users
- Toggle 2FA requirement
- Role assignment (future)

### 7. User Authentication & Security

**Features:**
- **Login/Logout:** Devise-powered
- **Password Reset:** Email-based (if configured)
- **Two-Factor Authentication:**
  - TOTP setup with QR code
  - Backup codes (future)
  - OTP verification on login
  - Force 2FA for admins (optional)

- **Session Management:**
  - Remember me (optional)
  - Timeout after inactivity
  - Concurrent session handling

### 8. Documentation

**Features:**
- Built-in documentation viewer
- Markdown rendering (Redcarpet)
- Search functionality (future)
- Version-specific docs (future)
- Context-sensitive help (future)

### 9. Notifications

**Gotify Integration:**
- Application management (create/delete apps)
- Message sending via API
- User management
- Client token management
- Embedded admin panel (iframe)

**Notification Types:**
- CVE alerts (new vulnerabilities)
- Backup failures
- Task failures (threshold exceeded)
- Server status changes (future)
- System health alerts (future)

## User Workflows

### Onboarding a New Server

1. Admin generates minion installation script (Onboarding page)
2. Script executed on target server (curl | bash)
3. Minion connects to Salt Master (key pending)
4. Admin refreshes pending keys (Onboarding page)
5. Admin accepts minion key
6. Server appears in server list
7. Grains collected automatically
8. Server ready for management

### Executing a Command on Servers

1. Admin navigates to Dashboard or Server detail
2. Enters command in quick action form
3. Selects target (all/group/specific servers)
4. Submits command
5. Command queued to Sidekiq
6. Job executes via Salt API
7. Results appear in command history
8. Dashboard updates in real-time (Action Cable)

### Managing Vulnerabilities

1. Admin creates CVE watchlist (Settings → Vulnerability Lookup)
2. Configures package filter, severity, schedule
3. CveScanJob runs on schedule (Sidekiq Cron)
4. Python script queries vulnerability database
5. Alerts created for matches
6. Gotify notification sent
7. Admin reviews alerts (Vulnerability Alerts page)
8. Admin acknowledges, resolves, or ignores alerts
9. Alerts removed from active list

### Automated Backups

1. Admin configures backup (Settings → Backups)
2. Generates SSH key pair
3. Adds public key to remote Borg repo
4. Tests connection
5. Sets retention policy and schedule
6. Enables backups
7. BorgBackupJob runs on schedule
8. Backup created, encrypted, deduplicated
9. History recorded
10. Notification sent on failure

### Scheduled Task Execution

1. Admin creates task (Tasks → New)
2. Defines command, target, schedule
3. Enables task
4. TaskSchedulerJob monitors schedule (Sidekiq Cron)
5. Task triggered at scheduled time
6. TaskExecutionJob queued
7. Command executed via Salt API
8. Results recorded in task_runs
9. Alerts sent if thresholds exceeded

## Non-Functional Requirements

### Performance
- Dashboard load time: < 2 seconds
- Command execution initiation: < 1 second
- Real-time update latency: < 500ms
- Support 100+ managed servers
- Handle 1000+ concurrent WebSocket connections

### Scalability
- Horizontal scaling via Kamal (future)
- Database connection pooling (Puma default: 5 per thread)
- Redis for session sharing (multi-server)
- Background job concurrency (Sidekiq: 5-25 threads)

### Reliability
- Service auto-restart (systemd)
- Job retry logic (Sidekiq: 3 retries with exponential backoff)
- Database transaction safety
- Backup verification
- Health check endpoint (/up)

### Security
- HTTPS enforced (Caddy with Let's Encrypt)
- Rate limiting (5 req/sec per IP)
- CSRF protection
- SQL injection prevention (ActiveRecord)
- XSS prevention (Rails default escaping)
- API token encryption
- Session encryption
- 2FA enforcement (optional)

### Maintainability
- Automated installer with rollback
- Comprehensive logging (Rails logger)
- Error tracking (future: Sentry)
- Code style enforcement (RuboCop)
- Security audits (Brakeman)

### Compatibility
- **Operating Systems:**
  - Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
  - Debian 11 (Bullseye), 12 (Bookworm)
  - Rocky Linux 9 (future)

- **Browsers:**
  - Chrome/Edge (latest 2 versions)
  - Firefox (latest 2 versions)
  - Safari (latest 2 versions)

### Monitoring & Observability
- Application logs (Rails logger)
- Systemd journal integration
- Sidekiq web UI (future)
- Database query logging
- APM integration (future: New Relic, Skylight)

## Deployment Architecture

### Production Environment

**Server Requirements:**
- Ubuntu 22.04 LTS or Debian 12 (recommended)
- 4+ CPU cores
- 8GB+ RAM
- 20GB+ SSD storage
- Static IP or FQDN with DNS

**Installed Services:**
- PostgreSQL 14+ (primary database)
- Redis 7+ (cache, jobs, cable)
- SaltStack Master + API (minion management)
- Caddy v2 (reverse proxy + HTTPS)
- Docker (Gotify container)
- Puma (Rails app server)
- Sidekiq (background workers)

**File Locations:**
- Application: `/opt/veracity/app`
- Logs: `/opt/veracity/app/log`
- Python venv: `/opt/veracity/app/cve_venv`
- Salt states: `/srv/salt`
- Salt pillars: `/srv/pillar`
- Gotify data: `/var/lib/gotify`
- Systemd services: `/etc/systemd/system`
- Caddy config: `/etc/caddy/Caddyfile`

**Network Ports:**
- 80/tcp - HTTP (redirects to HTTPS)
- 443/tcp - HTTPS (Caddy)
- 4505/tcp - Salt Publisher
- 4506/tcp - Salt Request Server
- 8080/tcp - Gotify (internal only)
- 8000/tcp - Salt API (internal only)
- 5432/tcp - PostgreSQL (internal only)
- 6379/tcp - Redis (internal only)

### Installation Process

**Automated Installer:** `./install.sh`
- Checkpoint-based recovery
- Rollback capability
- Error logging and diagnostics
- Estimated time: 25-35 minutes

**Phases:**
1. Prerequisites check
2. PostgreSQL installation
3. Redis installation
4. SaltStack installation
5. Ruby installation (rbenv)
6. Node.js installation
7. Caddy installation
8. Gotify installation (Docker)
9. CVE scanner setup (Python venv)
10. Application deployment
11. Database setup
12. Asset compilation
13. Admin user creation
14. Service installation
15. Firewall configuration
16. Health checks

### Update Process

**Automated Updater:** `/opt/veracity/app/scripts/update.sh`
- Backup creation
- Git pull (main branch)
- Dependency updates (exact versions from lock files)
- Database migrations
- Asset precompilation
- Service restart
- Health checks

**Rollback:** Restore from backup in `/opt/backups`

## Testing Strategy

### Current State
- Test framework: Minitest (Rails default)
- Test gems installed: FactoryBot, Faker, WebMock, Mocha, SimpleCov
- Test coverage: 0% ⚠️ **CRITICAL ISSUE**

### Recommended Test Coverage

**Unit Tests (Models):**
- Validations
- Associations
- Scopes
- Business logic methods
- Encryption/decryption
- State transitions

**Controller Tests:**
- Authorization (Pundit policies)
- Happy paths
- Error handling
- Parameter validation
- Response formats

**Integration Tests:**
- Server onboarding workflow
- Command execution flow
- CVE scanning process
- Backup execution
- Task scheduling and execution
- API integrations (mocked)

**System Tests (End-to-End):**
- User login with 2FA
- Dashboard real-time updates
- Server management operations
- Alert workflow
- Task creation and execution

**Job Tests:**
- Sidekiq job execution
- Retry logic
- Error handling
- External API interactions (mocked)

### Code Quality Tools
- **Brakeman:** Security vulnerability scanning
- **RuboCop:** Code style enforcement
- **SimpleCov:** Code coverage reporting (target: 80%+)

## Known Issues & Technical Debt

### Critical
1. **No test coverage** - Significant regression risk
2. **Schema file not generated** - Makes database structure unclear

### High Priority
1. Large controller files (20KB+) - Refactoring needed
2. Command injection risk - Input sanitization review needed
3. No error tracking - Sentry/Honeybadger integration recommended

### Medium Priority
1. No API documentation - API endpoint documentation needed
2. No developer setup guide - Separate from installation guide
3. Job failure monitoring - Dead job queue handling

### Low Priority
1. OAuth not fully implemented - Only scaffold present
2. User roles not implemented - Only admin role exists
3. Backup verification - No restore testing

## Future Enhancements

### Planned Features (Roadmap)
- OAuth2/Zitadel integration (SSO)
- Role-based access control (admin, operator, viewer)
- Multi-tenancy support
- API endpoint for external integrations
- Mobile app (future consideration)
- Advanced reporting and analytics
- Container orchestration (Kubernetes support)
- AWS/Azure/GCP integration
- Ansible playbook integration
- Terraform integration
- Slack/Discord notifications
- Email notifications
- Advanced metrics (Prometheus/Grafana)
- Log aggregation (ELK stack)
- Cost tracking (cloud providers)
- Capacity planning tools
- Compliance reporting (SOC2, HIPAA, etc.)

### Technical Improvements
- Comprehensive test suite (target: 80%+ coverage)
- API documentation (OpenAPI/Swagger)
- Performance optimization (N+1 query elimination)
- Caching strategy (Russian doll caching)
- Database query optimization
- Service object extraction (fat controller refactoring)
- Event sourcing for audit trail
- GraphQL API (alternative to REST)
- WebSocket security hardening
- Rate limiting per user (not just per IP)

## Maintenance & Operations

### Backup Strategy
- **Application Code:** Git repository
- **Database:** Automated backups via BorgBackup
- **Configuration:** `/opt/veracity/app/.env.production` (excluded from Git)
- **Credentials:** `/root/veracity-install-credentials.txt`

### Monitoring
- **Service Health:** systemctl status checks
- **Application Logs:** `/opt/veracity/app/log/production.log`
- **Job Queue:** Sidekiq dashboard (future)
- **Database:** PostgreSQL slow query log
- **Web Server:** Caddy access logs

### Troubleshooting
- **Installation Issues:** `./scripts/install/diagnose.sh`
- **Service Failures:** `journalctl -u <service> -f`
- **Database Issues:** Rails console access
- **Job Failures:** Sidekiq dead set inspection
- **Network Issues:** Salt API connectivity tests

### Regular Maintenance
- Weekly: Review failed jobs, clear old commands
- Monthly: Review vulnerability alerts, update dependencies
- Quarterly: Security audit (Brakeman), performance review
- Annually: Disaster recovery test, backup restoration test

## Documentation References

### Official Documentation
- Project Docs: https://pwoodlock.github.io/veracity-/
- Quick Start: https://pwoodlock.github.io/veracity-/docs/intro
- GitHub Repo: https://github.com/Pwoodlock/veracity-

### External Dependencies
- Rails 8.1: https://guides.rubyonrails.org/
- SaltStack: https://docs.saltproject.io/
- Devise: https://github.com/heartcombo/devise
- Sidekiq: https://github.com/sidekiq/sidekiq
- Caddy: https://caddyserver.com/docs/
- BorgBackup: https://borgbackup.readthedocs.io/
- Gotify: https://gotify.net/docs/
- Hetzner API: https://docs.hetzner.cloud/
- Proxmox API: https://pve.proxmox.com/pve-docs/api-viewer/

## Conclusion

Veracity is a well-architected, feature-rich infrastructure management platform with a modern technology stack. The application successfully integrates multiple complex systems (SaltStack, cloud providers, CVE scanning) into a cohesive, user-friendly interface.

**Key Strengths:**
- Modern Rails 8 stack with Solid Queue/Cache/Cable
- Comprehensive security features (2FA, CVE monitoring, encrypted credentials)
- Real-time updates via Action Cable and Turbo
- Multi-cloud provider support
- Automated installation and update processes

**Critical Improvements Needed:**
- Implement comprehensive test suite (0% → 80%+)
- Security audit for command injection vulnerabilities
- Refactor large controller files into service objects
- Add error tracking and monitoring
- Generate proper database schema file

The platform is production-ready with the caveat that critical test coverage must be implemented to ensure stability and maintainability as the codebase evolves.
