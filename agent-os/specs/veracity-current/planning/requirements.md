# Veracity Infrastructure Management Platform - Requirements Document

## Project Information

**Project Name:** Veracity
**Version:** 0.0.1-alpha
**Document Version:** 1.0
**Last Updated:** 2025-11-17
**Status:** Active Development

## Executive Summary

This document outlines the comprehensive requirements for the Veracity Infrastructure Management Platform, a Ruby on Rails 8.1.1 application that provides centralized server management, security monitoring, automated backups, and multi-cloud provider integration through SaltStack orchestration.

## Stakeholders

**Primary:**
- System Administrators
- DevOps Engineers
- Infrastructure Teams
- Security Operations Teams

**Secondary:**
- IT Management
- Compliance Officers
- Development Teams (for self-service infrastructure)

## Business Requirements

### BR-1: Infrastructure Centralization
**Priority:** CRITICAL
**Description:** Provide a single interface to manage all infrastructure (physical servers, Hetzner Cloud, Proxmox VE)
**Success Criteria:**
- Support 100+ managed servers
- Unified dashboard view
- Real-time status updates
- Less than 2-second dashboard load time

### BR-2: Security & Compliance
**Priority:** CRITICAL
**Description:** Automated vulnerability detection and compliance monitoring
**Success Criteria:**
- Daily CVE scans
- Automatic alert generation
- Alert workflow management
- Notification delivery within 5 minutes of detection

### BR-3: Automation & Efficiency
**Priority:** HIGH
**Description:** Reduce manual server management tasks by 80%
**Success Criteria:**
- One-click command execution across server groups
- Scheduled task automation
- Task templates for common operations
- Audit trail for all actions

### BR-4: Data Protection
**Priority:** CRITICAL
**Description:** Reliable, automated backup system with encryption
**Success Criteria:**
- Scheduled backups (configurable frequency)
- Encrypted, deduplicated storage
- Backup verification
- Disaster recovery capability

### BR-5: Multi-Cloud Support
**Priority:** HIGH
**Description:** Unified management for multiple cloud providers
**Success Criteria:**
- Hetzner Cloud integration (power control, snapshots)
- Proxmox VE integration (VM/LXC management)
- Future: AWS, Azure, GCP support

## Functional Requirements

### FR-1: User Authentication & Authorization

#### FR-1.1: User Login
**Priority:** CRITICAL
- Email/password authentication via Devise
- Session management with configurable timeout
- Remember me functionality (optional)
- Password strength requirements enforced
- Account lockout after 5 failed attempts

#### FR-1.2: Two-Factor Authentication
**Priority:** CRITICAL
- TOTP-based 2FA (Google Authenticator compatible)
- QR code generation for setup
- Backup codes (6 codes) for account recovery
- Force 2FA for admin accounts (configurable)
- 2FA status visible in user management

#### FR-1.3: User Management
**Priority:** HIGH
- Admin can create/edit/delete users
- User roles: Admin (current), Operator (future), Viewer (future)
- Toggle 2FA requirement per user
- User activity logging
- Last login timestamp tracking

#### FR-1.4: Password Management
**Priority:** HIGH
- Password reset via email (if configured)
- Password change from profile
- Password expiration policy (future)
- Password history (prevent reuse)

### FR-2: Dashboard & Monitoring

#### FR-2.1: Dashboard Overview
**Priority:** CRITICAL
- Server status summary (online/offline/unreachable counts)
- Recent command history (last 10 executions)
- Active vulnerability alerts (unresolved count with severity breakdown)
- Quick action buttons (execute command, sync minions, check updates)
- System metrics charts (CPU, memory, disk usage over time)
- Failed commands widget with bulk clear action
- Real-time updates via WebSockets (Action Cable)

#### FR-2.2: Quick Actions
**Priority:** HIGH
- Execute ad-hoc command on all/group/specific servers
- Trigger minion synchronization
- Check for system updates across all servers
- Trigger security update installation
- Clear failed commands (bulk action)

#### FR-2.3: Real-Time Updates
**Priority:** HIGH
- Server status changes appear immediately
- Command completions update dashboard without refresh
- New vulnerability alerts appear in real-time
- Metric charts update every 5 minutes
- WebSocket reconnection handling

### FR-3: Server Management

#### FR-3.1: Server Listing
**Priority:** CRITICAL
- Paginated server list (configurable items per page)
- Columns: Hostname, IP, OS, Status, Last Seen, Actions
- Search by hostname, IP, OS
- Filter by status (online/offline/unreachable)
- Filter by group
- Sort by any column
- Bulk actions: Add to group, execute command, delete

#### FR-3.2: Server Detail View
**Priority:** HIGH
- System information panel:
  - Hostname, IP address, FQDN
  - Operating system, version, kernel
  - Architecture (x86_64, ARM, etc.)
  - Salt minion version
  - Last seen timestamp
- Salt grain data (formatted JSON):
  - Installed packages
  - Network interfaces
  - Disk partitions
  - CPU info, memory
- Metric charts (selectable time range: 24h/7d/30d):
  - CPU usage (%)
  - Memory usage (%)
  - Disk usage (%) per partition
  - Network I/O (bytes in/out)
- Command history for this server (last 50)
- Related vulnerability alerts
- Quick actions: Sync, diagnose, execute command

#### FR-3.3: Server Onboarding
**Priority:** CRITICAL
- Generate minion installation script:
  - Detects server OS (Ubuntu/Debian/Rocky)
  - Pre-configures master IP
  - Installs Salt minion
  - Starts minion service
- Display pending minion keys
- Accept/reject keys with confirmation
- Auto-refresh pending keys (every 10 seconds)
- Bulk accept/reject (future)

#### FR-3.4: Server Diagnostics
**Priority:** HIGH
- Connection troubleshooting:
  - Ping test (ICMP)
  - Salt connectivity test
  - Grain refresh test
- Salt version compatibility check
- Minion log retrieval (last 100 lines)
- Manual grain refresh trigger
- Diagnostic results displayed with timestamps
- Error messages with remediation suggestions

#### FR-3.5: Cloud Provider Integration - Hetzner
**Priority:** HIGH
- Link server to Hetzner Cloud instance (server_id)
- Display Hetzner-specific info:
  - Server type (CPX11, CPX21, etc.)
  - Datacenter location
  - Public/private IPs
  - Pricing
- Power control actions:
  - Start (if powered off)
  - Stop (forced shutdown)
  - Reboot (graceful restart)
- Status synchronization (manual refresh button)
- Snapshot management:
  - List existing snapshots
  - Create snapshot (with name/description)
  - Delete snapshot (with confirmation)
- Server discovery: Auto-populate dropdown with Hetzner servers

#### FR-3.6: Cloud Provider Integration - Proxmox
**Priority:** HIGH
- Link server to Proxmox VM/LXC (vm_id, node)
- Display Proxmox-specific info:
  - VM type (qemu/lxc)
  - Node name
  - CPU cores, memory
  - Disk size
  - Network configuration
- Power control actions:
  - Start (if stopped)
  - Stop (forced shutdown)
  - Shutdown (graceful)
  - Reboot (graceful restart)
- Status synchronization (manual refresh button)
- Snapshot management:
  - List existing snapshots
  - Create snapshot (with name/description)
  - Rollback to snapshot (with confirmation)
  - Delete snapshot (with confirmation)
- VM/LXC discovery: Auto-populate dropdown with Proxmox resources

#### FR-3.7: Server Groups
**Priority:** MEDIUM
- Create/edit/delete groups
- Add/remove servers from groups
- Bulk actions on group members
- Group-based targeting for commands/tasks

### FR-4: Task Automation

#### FR-4.1: Task Management
**Priority:** HIGH
- Create task with:
  - Name (required, unique)
  - Description (optional, markdown support)
  - Command (required, Salt command syntax)
  - Target: all servers / specific group / specific servers
  - Schedule: one-time / cron expression
  - Enabled flag (can disable without deleting)
  - Alert thresholds:
    - Max consecutive failures (default: 3)
    - Max duration (timeout in seconds)
- Edit existing tasks (preserves history)
- Delete tasks (soft delete with confirmation)
- Enable/disable tasks (toggle without editing)

#### FR-4.2: Task Templates
**Priority:** MEDIUM
- Predefined task templates:
  - System updates (full: `apt update && apt upgrade -y`)
  - Security updates only (`apt update && apt upgrade -y --security`)
  - Package installation (`apt install -y <package>`)
  - Service restart (`systemctl restart <service>`)
  - Disk cleanup (`apt autoremove -y && apt clean`)
  - Custom commands
- Template categories: Updates, Maintenance, Monitoring, Custom
- Use template to create new task (pre-fills fields)
- Template library (expandable by admins)

#### FR-4.3: Task Execution
**Priority:** CRITICAL
- Manual trigger (Execute Now button)
- Scheduled execution via Sidekiq Cron
- Execution tracking:
  - Status: pending → running → completed/failed
  - Started at, completed at, duration
  - Output (stdout/stderr)
  - Exit code
  - Triggered by (user or scheduler)
- Real-time progress updates (Action Cable)
- Cancel running task (future)

#### FR-4.4: Task History
**Priority:** HIGH
- Task run list (paginated)
- Filter by:
  - Status (pending/running/completed/failed)
  - Date range (last 7d/30d/90d/custom)
  - Task name
  - Triggered by
- Display:
  - Task name
  - Status badge (color-coded)
  - Duration
  - Started/completed timestamps
  - Triggered by (user or scheduler)
  - Actions: View output, retry (future)
- Detail view:
  - Full output (syntax highlighted)
  - Error messages (if failed)
  - Exit code
  - Target servers
  - Command executed

#### FR-4.5: Task Alerting
**Priority:** MEDIUM
- Alert conditions:
  - Task fails N consecutive times (configurable per task)
  - Task exceeds max duration (timeout)
- Alert delivery:
  - Gotify notification
  - Dashboard alert widget
  - Email (future)
- Alert resolution:
  - Auto-resolve on successful run
  - Manual resolution

### FR-5: CVE Monitoring & Vulnerability Management

#### FR-5.1: Watchlist Management
**Priority:** CRITICAL
- Create watchlist with:
  - Name (required, unique)
  - Description (optional)
  - Package filter (regex, e.g., `^nginx|^apache`)
  - Severity threshold (low/medium/high/critical)
  - Schedule (cron expression, default: daily at 2am)
  - Enabled flag
  - Notification settings:
    - Enable Gotify notifications
    - Notification priority (1-10)
- Edit existing watchlists
- Delete watchlists (with confirmation)
- Enable/disable watchlists

#### FR-5.2: Watchlist Testing
**Priority:** HIGH
- Test button (immediate scan without waiting for schedule)
- Progress indicator during scan
- Display results:
  - Alerts generated count
  - Scan duration
  - Errors (if any)
- Debug view:
  - Raw API request
  - Raw API response (JSON)
  - Package matches

#### FR-5.3: Vulnerability Scanning
**Priority:** CRITICAL
- Scheduled scans via Sidekiq Cron (configurable per watchlist)
- On-demand scans (test button)
- Scan process:
  1. Query PyVulnerabilityLookup for packages matching filter
  2. Filter results by severity threshold
  3. Create VulnerabilityAlert for each match
  4. Associate alerts with affected servers (based on installed packages)
  5. Send Gotify notification (if enabled)
  6. Record scan in cve_scan_history
- Scan error handling:
  - Log errors to cve_scan_history
  - Retry on transient failures (3 attempts)
  - Alert on persistent failures

#### FR-5.4: Vulnerability Alerts
**Priority:** CRITICAL
- Alert list (paginated):
  - Columns: CVE ID, Package, Severity, Status, Affected Servers, Published Date
  - Severity badges (color-coded: critical=red, high=orange, medium=yellow, low=gray)
- Filter by:
  - Status (new/acknowledged/resolved/ignored)
  - Severity (critical/high/medium/low)
  - Date range (published date)
  - Package name
  - CVE ID
- Bulk actions:
  - Acknowledge (mark as reviewed)
  - Resolve (fixed)
  - Ignore (not applicable)
- Alert detail view:
  - CVE ID (link to external CVE database)
  - Package name and version
  - Severity and CVSS score
  - Description (full CVE description)
  - Published date
  - Affected servers (list with links)
  - Remediation suggestions
  - Status history (who changed status, when)

#### FR-5.5: Alert Workflow
**Priority:** HIGH
- Status states: new → acknowledged → resolved/ignored
- Status transitions:
  - New: Alert created by scan
  - Acknowledged: Admin reviewed, working on fix
  - Resolved: Fix applied and verified
  - Ignored: Not applicable or accepted risk
- Status change requires:
  - Confirmation (button click)
  - Optional note (reason for status change)
  - Timestamp and user tracking
- Bulk status changes (select multiple alerts)

#### FR-5.6: Scan History
**Priority:** MEDIUM
- Scan log per watchlist
- Display:
  - Scan timestamp
  - Duration
  - Alerts generated count
  - Status (success/failed)
  - Error messages (if failed)
- Retention: 90 days (configurable)

#### FR-5.7: CVE Notifications
**Priority:** HIGH
- Gotify notification on new alerts:
  - Title: "New Vulnerability Alert: <CVE-ID>"
  - Message: "<Package> (<Severity>) - <Description>"
  - Priority: Based on severity (critical=10, high=8, medium=5, low=3)
- Notification includes:
  - CVE ID
  - Package name
  - Severity
  - Affected servers count
  - Link to alert detail view
- Configurable per watchlist (enable/disable)

### FR-6: Backup Management

#### FR-6.1: Backup Configuration
**Priority:** HIGH
- Configure BorgBackup settings:
  - Repository URL (ssh://user@host/path/to/repo)
  - Repository password (encrypted)
  - SSH key pair:
    - Generate new key pair (4096-bit RSA)
    - Display public key (for adding to remote server)
    - Store private key (encrypted)
  - Backup paths (comma-separated):
    - Default: `/opt/veracity/app, /etc, /var/log`
  - Exclusion patterns (regex):
    - Default: `*.log, tmp/*, log/*`
  - Schedule (cron expression, default: daily at 3am)
  - Retention policy:
    - Daily backups to keep (default: 7)
    - Weekly backups to keep (default: 4)
    - Monthly backups to keep (default: 6)
  - Enabled flag
- Test connection:
  - SSH connectivity test
  - Borg repository access test
  - Write permission test
- Clear configuration (delete with confirmation)

#### FR-6.2: Backup Execution
**Priority:** CRITICAL
- Scheduled execution via Sidekiq (cron-based)
- Manual trigger (Run Now button)
- Backup process:
  1. Connect to remote repo via SSH
  2. Initialize repo if not exists
  3. Create archive with timestamp: `veracity-{hostname}-{YYYYMMDD-HHMMSS}`
  4. Borg creates (compressed, deduplicated, encrypted)
  5. Prune old archives per retention policy
  6. Record backup in backup_history
  7. Send notification (Gotify) on failure
- Progress tracking:
  - Status: pending → running → completed/failed
  - Started at, completed at, duration
  - Archive name, size
- Error handling:
  - Retry on transient failures (1 retry)
  - Log errors to backup_history
  - Alert on failure (Gotify)

#### FR-6.3: Backup History
**Priority:** HIGH
- Backup log (paginated)
- Display:
  - Backup timestamp
  - Status badge (success/failed)
  - Duration
  - Archive name
  - Archive size (compressed)
  - Error messages (if failed)
- Filter by:
  - Status (success/failed)
  - Date range (last 30d/90d/1y/all)
- Retention: Unlimited (or configurable)

#### FR-6.4: Backup Restoration (Future)
**Priority:** LOW
- List available archives
- Select archive to restore
- Choose restoration path
- Confirm restoration (with warning)
- Progress tracking
- Verification after restore

#### FR-6.5: Backup Notifications
**Priority:** MEDIUM
- Gotify notification on backup failure:
  - Title: "Backup Failed"
  - Message: "<Error message>"
  - Priority: High (8)
- Daily backup summary (future):
  - Title: "Daily Backup Summary"
  - Message: "<Successful count> / <Total count> backups completed"
  - Priority: Low (3)

### FR-7: Command Execution & History

#### FR-7.1: Command Execution
**Priority:** CRITICAL
- Ad-hoc command execution from:
  - Dashboard (quick action)
  - Server detail view
  - Command execution page
- Command input:
  - Command string (Salt cmd.run syntax)
  - Target selection:
    - All servers
    - Specific group (dropdown)
    - Specific servers (multi-select)
  - Timeout (seconds, default: 30)
- Command validation:
  - Non-empty command
  - Valid target selection
  - Timeout within limits (1-600 seconds)
- Execution process:
  1. Create Command record (status: pending)
  2. Queue to Sidekiq
  3. Execute via Salt API
  4. Update Command record (status: running)
  5. Capture results (stdout/stderr, exit code)
  6. Update Command record (status: completed/failed)
  7. Broadcast update via Action Cable
- Real-time progress updates (dashboard)

#### FR-7.2: Command History
**Priority:** HIGH
- Command log (paginated, latest first)
- Display:
  - Command string (truncated to 100 chars)
  - Target (all/group/servers count)
  - Status badge (pending/running/completed/failed)
  - Executed by (user)
  - Timestamp
  - Duration
  - Actions: View details, retry (future)
- Filter by:
  - Status (pending/running/completed/failed)
  - Date range (last 24h/7d/30d/custom)
  - User (who executed)
  - Target
- Command detail view:
  - Full command string
  - Target servers (list with links)
  - Status, timestamps, duration
  - Results per server:
    - Server name (link)
    - Exit code
    - Output (syntax highlighted)
    - Error messages (if any)
  - User who executed (link)

#### FR-7.3: Command Cleanup
**Priority:** MEDIUM
- Clear failed commands (bulk delete):
  - Dashboard widget button
  - Settings → Maintenance page
  - Confirmation required
- Clear old commands (retention policy):
  - Delete commands older than N days (default: 90)
  - Configurable in Settings
  - Manual trigger or scheduled (monthly)
- Soft delete vs. hard delete (configurable)

### FR-8: Settings & Configuration

#### FR-8.1: Appearance Settings
**Priority:** LOW
- Custom logo upload:
  - Upload via form (Active Storage)
  - Supported formats: PNG, JPG, SVG
  - Max file size: 2MB
  - Automatic resize: 200x200px
  - Preview before save
- Remove logo (reset to default)
- Company name:
  - Text input (max 100 chars)
  - Displayed in header, login page
- Company tagline:
  - Text input (max 200 chars)
  - Displayed below company name
- Preview panel (live preview of changes)

#### FR-8.2: Hetzner Cloud API Settings
**Priority:** HIGH
- API key management:
  - Add API key:
    - Name (descriptive label)
    - API token (encrypted)
    - Test connection on save
  - Edit API key:
    - Update name or token
    - Re-test connection
  - Delete API key (with confirmation)
  - Enable/disable key (toggle without deleting)
- API key list:
  - Columns: Name, Status (enabled/disabled), Last Tested, Actions
  - Status indicator (green=connected, red=failed, gray=not tested)
- Test connection:
  - Manual test button per key
  - Tests: List servers API call
  - Display test results (success/error message)
  - Update last tested timestamp
- Server discovery:
  - List all Hetzner servers for this API key
  - Pre-populate server form when linking

#### FR-8.3: Proxmox API Settings
**Priority:** HIGH
- API key management:
  - Add API key:
    - Name (descriptive label)
    - Host (IP or FQDN)
    - Port (default: 8006)
    - Verify SSL (checkbox, default: true)
    - User (e.g., root@pam)
    - Token name
    - Token value (encrypted)
    - Test connection on save
  - Edit API key:
    - Update any field
    - Re-test connection
  - Delete API key (with confirmation)
  - Enable/disable key (toggle without deleting)
- API key list:
  - Columns: Name, Host, Status, Last Tested, Actions
  - Status indicator (green=connected, red=failed, gray=not tested)
- Test connection:
  - Manual test button per key
  - Tests: List nodes, list VMs/LXCs
  - Display test results (success/error message)
  - Update last tested timestamp
  - Cache node list on success
- VM/LXC discovery:
  - List all VMs/LXCs for this API key
  - Pre-populate server form when linking
  - Display per node

#### FR-8.4: Gotify Notification Settings
**Priority:** HIGH
- Gotify configuration:
  - Server URL (default: http://localhost:8080)
  - Admin username
  - Admin password (encrypted)
  - SSL verification (checkbox, default: true)
- Test connection:
  - Manual test button
  - Tests: Get server health
  - Display test results (version, success/error)
- Admin panel link:
  - Embedded iframe to Gotify admin UI
  - Or external link in new tab
- Application management (embedded):
  - Create application (for Veracity)
  - Get application token (for sending messages)
  - List existing applications
  - Delete applications

#### FR-8.5: PyVulnerabilityLookup Settings
**Priority:** HIGH
- CVE scanner configuration:
  - Python executable path (default: auto-detected)
  - Virtual environment path (default: /opt/veracity/app/cve_venv)
  - Database update frequency (daily/weekly, default: daily)
- Test connection:
  - Manual test button
  - Tests: Run sample CVE query
  - Display test results (version, success/error)
  - Shows Python version, venv status
- Python info:
  - Display Python version
  - Display pip packages (vulnerability-lookup version)
  - Check for updates
- Manual scan trigger:
  - Run database update (download latest CVEs)
  - Progress indicator
  - Display results (updated CVE count)

#### FR-8.6: Email Settings (Future)
**Priority:** LOW
- SMTP configuration:
  - Server host
  - Port (25/465/587)
  - Username, password (encrypted)
  - Authentication method (plain/login/cram_md5)
  - TLS/SSL (checkbox)
- Test email:
  - Send test email to admin
  - Display results (success/error)
- Sender settings:
  - From address
  - From name

#### FR-8.7: Maintenance Settings
**Priority:** MEDIUM
- Maintenance actions:
  - Clear failed commands:
    - Button (with confirmation)
    - Count of commands to delete
    - Success message
  - Clear old commands:
    - Retention period (days, default: 90)
    - Button (with confirmation)
    - Count of commands to delete
    - Success message
- Database health:
  - Database size
  - Table row counts
  - Bloat detection (future)
  - Vacuum/analyze (future)
- Cache management:
  - Clear Rails cache (button)
  - Redis info (memory usage, keys)
  - Clear Redis cache (button, with warning)

### FR-9: Notification System

#### FR-9.1: Gotify Integration
**Priority:** HIGH
- Send notifications via Gotify API:
  - Title (required)
  - Message (required, supports markdown)
  - Priority (1-10, default: 5)
  - Application token (from configuration)
- Notification types:
  - CVE alerts (critical vulnerabilities)
  - Backup failures
  - Task failures (threshold exceeded)
  - Server status changes (future)
  - System health alerts (future)
- Notification history:
  - Record in notification_history table
  - Display: Type, title, message, timestamp, status
  - Filter by type, date range

#### FR-9.2: In-App Notifications (Future)
**Priority:** LOW
- Notification bell icon (header)
- Unread count badge
- Notification dropdown:
  - List recent notifications
  - Mark as read
  - Link to related item (alert, task, etc.)
- Notification preferences:
  - Enable/disable per notification type
  - Delivery method (Gotify, in-app, email)

### FR-10: Documentation

#### FR-10.1: Built-In Documentation
**Priority:** LOW
- Documentation viewer (authenticated):
  - Markdown rendering (Redcarpet)
  - Syntax highlighting (future)
  - Table of contents (auto-generated)
- Documentation sections:
  - Getting started
  - User guide
  - Admin guide
  - API reference (future)
  - Troubleshooting
- Search functionality (future):
  - Full-text search
  - Keyword highlighting

#### FR-10.2: Context-Sensitive Help (Future)
**Priority:** LOW
- Help icon on each page
- Tooltip help text
- Link to relevant documentation section
- Video tutorials (future)

## Non-Functional Requirements

### NFR-1: Performance

#### NFR-1.1: Response Times
- Dashboard load time: < 2 seconds (first load)
- Dashboard load time: < 500ms (subsequent loads, cached)
- Command execution initiation: < 1 second
- Real-time update latency: < 500ms (WebSocket)
- API response time: < 200ms (average)
- Database query time: < 100ms (95th percentile)

#### NFR-1.2: Scalability
- Support 100+ managed servers (initial target)
- Support 500+ managed servers (6-month target)
- Support 1000+ concurrent WebSocket connections
- Handle 100+ simultaneous command executions
- Process 1000+ background jobs per hour

#### NFR-1.3: Resource Usage
- Application memory: < 1GB per Puma worker
- Database connection pool: 5 per thread (Puma default)
- Sidekiq concurrency: 5-25 threads (configurable)
- Redis memory: < 500MB (cache + jobs)
- PostgreSQL: < 10GB database size (100 servers, 90 days history)

### NFR-2: Reliability

#### NFR-2.1: Availability
- Uptime: 99.5% (4.35 hours downtime per month acceptable)
- Service auto-restart on failure (systemd)
- Database backup: Daily (automated)
- Application backup: Daily (automated)

#### NFR-2.2: Data Integrity
- Database transactions for critical operations
- Foreign key constraints enforced
- Validation at model and controller levels
- Audit trail for destructive actions
- Soft delete for important records (servers, tasks)

#### NFR-2.3: Error Handling
- Job retry logic: 3 retries with exponential backoff (Sidekiq default)
- Graceful degradation (if Redis down, show cached data)
- User-friendly error messages (no stack traces to users)
- Error logging (Rails logger + future: Sentry)
- Health check endpoint (/up) for monitoring

### NFR-3: Security

#### NFR-3.1: Authentication & Authorization
- Strong password requirements:
  - Minimum 12 characters
  - Mix of uppercase, lowercase, numbers, symbols
  - No common passwords (Devise zxcvbn gem)
- Session security:
  - Encrypted session cookies
  - Session timeout: 24 hours (configurable)
  - Logout on password change
- Two-factor authentication:
  - TOTP (RFC 6238 compliant)
  - 30-second time step
  - 6-digit code
- Rate limiting:
  - 5 requests per second per IP (Rack Attack)
  - 20 login attempts per hour per IP
  - 100 API calls per hour per user (future)

#### NFR-3.2: Data Protection
- Encryption at rest:
  - API tokens: AES-256-GCM (attr_encrypted)
  - Passwords: bcrypt (Devise default, cost: 12)
  - SSH keys: AES-256-GCM
  - Database: PostgreSQL native encryption (future)
- Encryption in transit:
  - HTTPS enforced (Caddy with Let's Encrypt)
  - TLS 1.2+ (Caddy default)
  - HSTS header (max-age: 31536000)
  - Salt communication: ZeroMQ CurveCP
- Secret management:
  - Environment variables (.env.production)
  - Rails encrypted credentials (credentials.yml.enc)
  - No secrets in code or version control
  - Credentials backed up securely

#### NFR-3.3: Input Validation & Sanitization
- SQL injection prevention:
  - ActiveRecord parameterized queries (Rails default)
  - No raw SQL (except for complex queries, parameterized)
- XSS prevention:
  - HTML escaping by default (Rails default)
  - Sanitize user input (Rails sanitize helper)
  - Content Security Policy (future)
- Command injection prevention:
  - Whitelist allowed commands (Salt state names)
  - Validate command syntax
  - Shell escaping (Shellwords.escape)
  - Audit all command executions
- CSRF protection:
  - CSRF token required for state-changing requests (Rails default)
  - SameSite cookie attribute

#### NFR-3.4: Vulnerability Management
- Dependency updates:
  - Weekly security patch checks (Dependabot, future)
  - Automated updates for minor versions
  - Manual review for major versions
- Security audits:
  - Brakeman static analysis (weekly)
  - Bundler-audit (weekly)
  - OWASP ZAP scan (monthly, future)
- CVE monitoring:
  - Automated scanning of managed servers (daily)
  - Alert on critical vulnerabilities (within 5 minutes)
  - Track remediation status

#### NFR-3.5: Audit Logging
- Log all security-relevant events:
  - User login/logout (success/failure)
  - 2FA enable/disable
  - Password changes
  - User creation/deletion
  - Permission changes
  - Command executions (who, what, when, where)
  - Configuration changes
  - API key usage
- Audit log retention: 1 year (configurable)
- Audit log tamper-proofing (future: append-only log)

### NFR-4: Usability

#### NFR-4.1: User Interface
- Responsive design (mobile/tablet/desktop)
- Browser support:
  - Chrome/Edge (latest 2 versions)
  - Firefox (latest 2 versions)
  - Safari (latest 2 versions)
- Accessibility (future):
  - WCAG 2.1 Level AA compliance
  - Keyboard navigation
  - Screen reader support
  - High contrast mode
- Dark mode (future)

#### NFR-4.2: User Experience
- Consistent navigation (header, breadcrumbs)
- Loading indicators (spinners, progress bars)
- Success/error messages (flash messages, toasts)
- Confirmation dialogs for destructive actions
- Contextual help (tooltips, help icons)
- Keyboard shortcuts (future: /, Ctrl+K for search)

#### NFR-4.3: Performance Perception
- Optimistic UI updates (update before server confirmation)
- Skeleton screens (loading placeholders)
- Pagination (avoid long lists)
- Lazy loading (images, charts)
- Caching (fragment caching, HTTP caching)

### NFR-5: Maintainability

#### NFR-5.1: Code Quality
- Code style: RuboCop Rails Omakase
- Code complexity: ABC metric < 20 per method
- Code duplication: < 5% (future: CodeClimate)
- Test coverage: 80%+ (SimpleCov)
- Code reviews: Required for all changes (future)

#### NFR-5.2: Documentation
- Code comments:
  - Public methods documented (RDoc format)
  - Complex logic explained
  - TODOs tracked
- Project documentation:
  - README.md (setup, deployment)
  - INSTALLATION.md (detailed installation)
  - CONTRIBUTING.md (development guide, future)
  - API.md (API documentation, future)
  - CHANGELOG.md (release notes, future)
- Architecture documentation:
  - System architecture diagram
  - Database schema diagram (future)
  - API architecture (future)

#### NFR-5.3: Testing
- Test framework: Minitest (Rails default)
- Test types:
  - Unit tests (models, jobs, helpers)
  - Controller tests (authorization, responses)
  - Integration tests (multi-step workflows)
  - System tests (end-to-end, browser-based)
- Test coverage:
  - Overall: 80%+
  - Critical paths: 100% (authentication, command execution, CVE scanning)
  - Models: 90%+
  - Controllers: 80%+
- Continuous integration (future):
  - Run tests on every commit
  - Run Brakeman, RuboCop
  - Deploy on green build

#### NFR-5.4: Logging & Monitoring
- Application logs:
  - Log level: INFO (production), DEBUG (development)
  - Log format: JSON (structured logging, future)
  - Log rotation: Daily, keep 30 days
  - Log aggregation (future: ELK, Splunk)
- Monitoring (future):
  - APM (New Relic, Skylight)
  - Error tracking (Sentry, Honeybadger)
  - Uptime monitoring (Pingdom, UptimeRobot)
  - Performance metrics (response times, throughput)
  - Resource metrics (CPU, memory, disk)

### NFR-6: Compatibility

#### NFR-6.1: Operating System Support
- **Server (Veracity application):**
  - Ubuntu 20.04 LTS (supported)
  - Ubuntu 22.04 LTS (supported, recommended)
  - Ubuntu 24.04 LTS (supported)
  - Debian 11 (Bullseye) (supported)
  - Debian 12 (Bookworm) (supported)
  - Rocky Linux 9 (planned)
  - AlmaLinux 9 (planned)
  - RHEL 9 (planned)

- **Managed Servers (Salt minions):**
  - Same as above
  - Additional: CentOS 7/8, Fedora, Arch Linux (best effort)

#### NFR-6.2: Software Dependencies
- Ruby 3.3.6 (via Mise/rbenv)
- Rails 8.1.1
- PostgreSQL 14+ (tested: 14, 15, 16)
- Redis 7+ (tested: 7.0, 7.2)
- SaltStack 3007.8 (critical: exact version or newer)
- Node.js 24 LTS (for asset compilation)
- Caddy v2 (tested: 2.6+)
- Docker 20.10+ (for Gotify)
- Python 3.8+ (for CVE scanner)

#### NFR-6.3: Cloud Provider APIs
- Hetzner Cloud API v1
- Proxmox VE API v2 (tested: Proxmox 7.x, 8.x)

### NFR-7: Deployment & Operations

#### NFR-7.1: Installation
- Automated installer:
  - Checkpoint-based (resume from failure)
  - Rollback capability
  - Estimated time: 25-35 minutes
  - Minimal user input (domain, email, password)
  - Pre-flight checks (OS, disk space, memory, ports)
- Installation modes:
  - Fresh install (recommended)
  - Upgrade from previous version (future)
  - Docker Compose (future)
  - Kubernetes Helm chart (future)

#### NFR-7.2: Updates
- Automated updater:
  - Backup before update
  - Git pull (main branch)
  - Dependency updates (lock file versions)
  - Database migrations
  - Asset precompilation
  - Service restart
  - Health checks
  - Rollback on failure
- Update frequency:
  - Security patches: As needed (within 24 hours)
  - Minor versions: Monthly
  - Major versions: Quarterly (with testing)

#### NFR-7.3: Backup & Recovery
- Backup strategy:
  - Database: Daily, keep 7 daily + 4 weekly + 6 monthly
  - Application files: Daily (via BorgBackup)
  - Configuration: Daily (/opt/veracity/app/.env.production)
  - Secrets: Encrypted backup (/root/veracity-install-credentials.txt)
- Recovery time objective (RTO): 1 hour
- Recovery point objective (RPO): 24 hours
- Disaster recovery test: Quarterly

#### NFR-7.4: Monitoring & Alerting
- Health checks:
  - Application: /up endpoint (200 OK)
  - Database: Connection pool health
  - Redis: Ping command
  - Salt API: Test connection
  - Sidekiq: Queue depth, dead jobs
- Alerts:
  - Service down (systemd failure)
  - Disk space < 10%
  - Memory usage > 90%
  - Database connection errors
  - Dead jobs > 10
  - CVE scan failures

## Testing Requirements

### TR-1: Unit Testing
- All models tested (validations, associations, methods)
- All jobs tested (execution, retry logic, error handling)
- All helpers tested (formatting, utilities)
- All service objects tested (business logic)
- Code coverage: 90%+ for models

### TR-2: Controller Testing
- All controllers tested (authorization, responses)
- Happy path tests (valid input, expected output)
- Sad path tests (invalid input, error handling)
- Authorization tests (Pundit policies)
- Code coverage: 80%+ for controllers

### TR-3: Integration Testing
- Server onboarding workflow (end-to-end)
- Command execution flow (queuing, execution, results)
- CVE scanning process (scan, alert, notify)
- Backup execution (schedule, execute, record)
- Task scheduling and execution (cron, trigger, complete)
- Code coverage: 100% for critical workflows

### TR-4: System Testing (End-to-End)
- User login with 2FA (QR code, OTP verification)
- Dashboard real-time updates (WebSocket, Action Cable)
- Server management operations (add, sync, command, delete)
- Alert workflow (create, acknowledge, resolve)
- Task creation and execution (schedule, trigger, view results)
- Browser testing: Chrome, Firefox, Safari

### TR-5: Performance Testing
- Load testing (simulate 100 concurrent users)
- Stress testing (identify breaking point)
- Response time testing (< 2s for 95th percentile)
- WebSocket stress testing (1000+ concurrent connections)
- Database query optimization (N+1 query detection)

### TR-6: Security Testing
- Penetration testing (OWASP Top 10)
- Vulnerability scanning (OWASP ZAP, Burp Suite)
- Static analysis (Brakeman)
- Dependency scanning (Bundler-audit)
- Authentication bypass attempts
- Authorization bypass attempts
- Command injection tests
- SQL injection tests
- XSS tests

## Acceptance Criteria

### AC-1: Core Functionality
- [ ] User can log in with email/password
- [ ] User can enable 2FA with QR code
- [ ] User can onboard new server (accept minion key)
- [ ] User can execute command on server(s)
- [ ] User can view command results in real-time
- [ ] User can create scheduled task
- [ ] User can create CVE watchlist
- [ ] User can view vulnerability alerts
- [ ] User can configure automated backups
- [ ] User can integrate Hetzner Cloud API
- [ ] User can integrate Proxmox VE API
- [ ] User can receive Gotify notifications

### AC-2: Real-Time Features
- [ ] Dashboard updates without refresh (WebSocket)
- [ ] Server status changes appear immediately
- [ ] Command results appear immediately
- [ ] New alerts appear immediately

### AC-3: Security
- [ ] All passwords hashed with bcrypt
- [ ] All API tokens encrypted with AES-256
- [ ] HTTPS enforced (no HTTP traffic)
- [ ] CSRF protection enabled
- [ ] Rate limiting enforced
- [ ] No SQL injection vulnerabilities (Brakeman clean)
- [ ] No XSS vulnerabilities (Brakeman clean)
- [ ] No command injection vulnerabilities

### AC-4: Performance
- [ ] Dashboard loads in < 2 seconds
- [ ] Command execution initiates in < 1 second
- [ ] Supports 100+ servers without degradation
- [ ] Handles 1000+ WebSocket connections
- [ ] Database queries < 100ms (95th percentile)

### AC-5: Testing
- [ ] 80%+ code coverage (SimpleCov)
- [ ] All models tested (90%+ coverage)
- [ ] All controllers tested (80%+ coverage)
- [ ] Critical workflows tested (100% coverage)
- [ ] Brakeman reports no security issues
- [ ] RuboCop reports no style violations

### AC-6: Documentation
- [ ] README.md complete (setup, deployment)
- [ ] INSTALLATION.md complete (detailed guide)
- [ ] API documented (if applicable)
- [ ] User guide available
- [ ] Admin guide available

## Constraints & Assumptions

### Constraints
- **Technology Stack:** Must use Ruby on Rails 8.1.1 (latest stable)
- **Database:** Must use PostgreSQL 14+ (no MySQL/MariaDB)
- **Orchestration:** Must use SaltStack (no Ansible/Puppet)
- **Budget:** Open-source project (no commercial licenses)
- **Team Size:** Solo developer (initially)
- **Timeline:** Alpha release (current), Beta in 3 months, v1.0 in 6 months

### Assumptions
- Users have basic Linux administration knowledge
- Managed servers are accessible via network (SSH, Salt ports)
- Servers have internet connectivity (for package updates, CVE database)
- DNS is configured (for HTTPS with Let's Encrypt)
- PostgreSQL and Redis are dedicated to Veracity (not shared)
- Salt minions run compatible OS (Ubuntu, Debian, Rocky Linux)

## Risks & Mitigations

### Risk: Command Injection Vulnerability
- **Impact:** Critical (remote code execution)
- **Probability:** Medium (if input not sanitized)
- **Mitigation:**
  - Whitelist allowed commands
  - Use Salt state names (not raw shell commands)
  - Shell escape all user input
  - Security audit (Brakeman, manual review)
  - Comprehensive testing (penetration tests)

### Risk: Salt Master Compromise
- **Impact:** Critical (control of all managed servers)
- **Probability:** Low (if properly secured)
- **Mitigation:**
  - Salt API authentication (external auth)
  - Firewall rules (restrict ports 4505, 4506)
  - Regular security updates
  - Audit logging
  - 2FA for admin accounts

### Risk: Database Performance Degradation
- **Impact:** High (slow dashboard, timeouts)
- **Probability:** Medium (as server count grows)
- **Mitigation:**
  - Database indexes on frequently queried columns
  - Query optimization (N+1 detection, eager loading)
  - Connection pooling (Puma default)
  - Pagination (avoid loading large datasets)
  - Caching (fragment caching, HTTP caching)
  - Database maintenance (vacuum, analyze)

### Risk: CVE Scanning Overload
- **Impact:** Medium (slow scans, high resource usage)
- **Probability:** Medium (large package lists)
- **Mitigation:**
  - Rate limiting (CVE API calls)
  - Caching (package metadata)
  - Asynchronous processing (Sidekiq)
  - Retry logic (transient failures)
  - Monitoring (scan duration, failure rate)

### Risk: WebSocket Connection Limits
- **Impact:** Medium (real-time updates fail)
- **Probability:** Low (for 100 servers)
- **Mitigation:**
  - Connection pooling (Redis pub/sub)
  - Horizontal scaling (multiple Puma instances)
  - Fallback to polling (if WebSocket fails)
  - Monitoring (connection count, errors)

### Risk: Backup Failure
- **Impact:** High (data loss in disaster)
- **Probability:** Medium (network issues, disk full)
- **Mitigation:**
  - Backup verification (test restore monthly)
  - Multiple backup destinations (future)
  - Monitoring (backup success rate)
  - Alerts (Gotify notification on failure)
  - Retention policy (keep multiple versions)

## Glossary

- **CVE:** Common Vulnerabilities and Exposures (standardized vulnerability identifier)
- **CVSS:** Common Vulnerability Scoring System (vulnerability severity metric)
- **Grain:** SaltStack term for system information (OS, packages, network, etc.)
- **Minion:** SaltStack agent running on managed server
- **Salt Master:** SaltStack orchestration server
- **Salt API:** REST API for Salt Master (port 8000)
- **State:** SaltStack configuration definition (declarative)
- **TOTP:** Time-Based One-Time Password (2FA method)
- **WebSocket:** Bi-directional communication protocol (for real-time updates)
- **Action Cable:** Rails WebSocket framework
- **Turbo Streams:** Rails real-time update mechanism (via WebSocket)
- **Sidekiq:** Ruby background job processor
- **BorgBackup:** Deduplicated, encrypted backup tool
- **Gotify:** Self-hosted push notification server
- **PyVulnerabilityLookup:** Python tool for querying CVE databases

## Appendices

### Appendix A: API Endpoints (Future)
- `/api/v1/servers` - List servers
- `/api/v1/servers/:id` - Get server details
- `/api/v1/commands` - Execute command
- `/api/v1/tasks` - List/create/execute tasks
- `/api/v1/alerts` - List vulnerability alerts
- Authentication: Bearer token (JWT)
- Rate limiting: 100 requests/hour per user

### Appendix B: Database Schema Summary
- `users` - Admin users
- `servers` - Managed servers
- `groups` - Server groups
- `server_metrics` - Time-series metrics
- `tasks` - Task definitions
- `task_runs` - Task execution history
- `task_templates` - Predefined tasks
- `cve_watchlists` - CVE monitoring configuration
- `vulnerability_alerts` - Detected vulnerabilities
- `cve_scan_history` - Scan execution log
- `backup_configurations` - Backup settings
- `backup_history` - Backup execution log
- `hetzner_api_keys` - Hetzner credentials
- `proxmox_api_keys` - Proxmox credentials
- `commands` - Command execution log
- `notification_history` - Notification log
- `system_settings` - Application configuration

### Appendix C: System Metrics
- **Servers Managed:** 0 (initial) → 100 (6 months) → 500 (1 year)
- **Commands Executed:** 1000/month (initial) → 10,000/month (6 months)
- **CVE Alerts:** 100/month (estimated)
- **Backups:** 30/month (daily backups)
- **Active Users:** 5 (initial) → 20 (6 months)

### Appendix D: Third-Party Services
- **GitHub:** Code repository, CI/CD (future)
- **Hetzner Cloud:** Cloud server provider (optional)
- **Proxmox VE:** Virtualization platform (optional)
- **Let's Encrypt:** SSL certificates (automatic via Caddy)
- **NVD (NIST):** National Vulnerability Database (via PyVulnerabilityLookup)

## Approval

**Document Prepared By:** AI Assistant (Claude)
**Date:** 2025-11-17
**Version:** 1.0

**Approval Required:**
- [ ] Project Owner: ____________________ Date: __________
- [ ] Technical Lead: ____________________ Date: __________
- [ ] Security Officer: ____________________ Date: __________

**Change History:**
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-17 | AI Assistant | Initial requirements document based on current codebase analysis |
