# Task Breakdown: Veracity Infrastructure Management Platform

## Overview

**Project:** Veracity Infrastructure Management Platform v0.0.1-alpha
**Framework:** Ruby on Rails 8.1.1
**Total Task Groups:** 11
**Estimated Total Tasks:** 130+

## Critical Priorities Addressed

This task breakdown specifically addresses the critical issues identified in the spec:

1. **Zero Test Coverage (0%)** - Task Groups 1-10 each include focused test writing
2. **Security Audit for Command Injection** - Task Group 2 (Security & Command Execution)
3. **Large Controller Files Need Refactoring** - Task Group 3 (Service Object Extraction)
4. **Schema File Not Generated** - Task Group 1.1 includes schema generation

## Execution Sequence Overview

The tasks are organized strategically to address critical issues first, then build comprehensive test coverage while maintaining the existing functionality:

1. **Foundation & Critical Fixes** (Task Group 1) - Schema generation, security audit, critical fixes
2. **Security Hardening** (Task Group 2) - Command injection prevention, input validation
3. **Code Refactoring** (Task Group 3) - Extract service objects from large controllers
4. **Core Testing - Models** (Task Group 4) - Test all database models and business logic
5. **Core Testing - Controllers** (Task Group 5) - Test authorization and API responses
6. **Integration Testing** (Task Group 6) - Test critical user workflows
7. **Feature Testing - Server Management** (Task Group 7) - Test server operations
8. **Feature Testing - CVE Monitoring** (Task Group 8) - Test vulnerability scanning
9. **Feature Testing - Tasks & Backups** (Task Group 9) - Test automation features
10. **System Testing** (Task Group 10) - End-to-end browser-based tests
11. **Test Coverage Analysis** (Task Group 11) - Review and fill gaps

---

## Task List

### Task Group 1: Foundation & Critical Fixes
**Dependencies:** None
**Priority:** CRITICAL
**Estimated Time:** 8-12 hours

#### Objective
Address the most critical issues that block development and pose security risks: generate schema file, perform security audit, and fix immediate vulnerabilities.

#### Tasks

- [ ] 1.0 Complete Foundation & Critical Fixes
  - [ ] 1.1 Generate database schema file
    - Run `rails db:schema:dump` to generate `db/schema.rb`
    - Verify schema file includes all tables, indexes, and foreign keys
    - Commit schema file to version control
    - Document schema generation process in README

  - [ ] 1.2 Security audit - Command injection vulnerabilities
    - Run Brakeman static analysis: `bundle exec brakeman -o brakeman-report.html`
    - Review all code that executes shell commands (Salt API calls, Borg, Python CVE scanner)
    - Identify locations where user input flows into shell commands
    - Document all findings in `SECURITY_AUDIT.md`
    - Create prioritized list of vulnerabilities by severity

  - [ ] 1.3 Fix critical command injection vulnerabilities
    - Review `SaltService` methods that execute commands
    - Implement `Shellwords.escape` for all user-provided command parameters
    - Review `BorgBackupJob` for injection risks in repository URLs and paths
    - Review `CveScanJob` for injection risks in package names
    - Add validation to reject dangerous characters in command inputs
    - Test fixes with malicious input samples (e.g., `; rm -rf /`, `$(malicious)`)

  - [ ] 1.4 Implement command whitelist system
    - Create `CommandValidator` service class
    - Define whitelist of allowed Salt state names and modules
    - Implement validation method that checks commands against whitelist
    - Add validation to `Command` model before execution
    - Update controllers to use `CommandValidator`
    - Document whitelisting approach in `SECURITY_AUDIT.md`

  - [ ] 1.5 Add audit logging for all command executions
    - Verify `Command` model records user association
    - Add before/after hooks to log command parameters
    - Ensure timestamp tracking for all command executions
    - Add IP address tracking (via `request.remote_ip`)
    - Create dashboard widget to display recent audit log entries

  - [ ] 1.6 Review and fix Rails security configuration
    - Verify `config.force_ssl = true` in production
    - Verify CSRF protection enabled
    - Review Content Security Policy settings
    - Verify secure session cookie configuration
    - Check for exposed secrets in code/version control
    - Update `.gitignore` to exclude sensitive files

**Acceptance Criteria:**
- Schema file (`db/schema.rb`) exists and is committed
- Brakeman security audit completed with detailed report
- Critical command injection vulnerabilities fixed (0 high/critical Brakeman warnings)
- Command whitelist system implemented and tested
- Audit logging captures user, timestamp, IP for all commands
- Rails security best practices verified

---

### Task Group 2: Security Hardening - Input Validation & Sanitization
**Dependencies:** Task Group 1
**Priority:** CRITICAL
**Estimated Time:** 10-15 hours

#### Objective
Implement comprehensive input validation and sanitization across all user-facing inputs to prevent injection attacks and ensure data integrity.

#### Tasks

- [ ] 2.0 Complete Security Hardening
  - [ ] 2.1 Write 5-8 focused tests for command validation
    - Test `CommandValidator` rejects commands not in whitelist
    - Test shell escaping for user-provided parameters
    - Test validation rejects dangerous characters (`;`, `|`, `$()`, etc.)
    - Test validation allows safe Salt commands (e.g., `state.apply`)
    - Test audit logging captures command details

  - [ ] 2.2 Implement input validation for server management
    - Add validation to `Server` model:
      - Hostname: alphanumeric, hyphens, dots only (regex: `/\A[a-zA-Z0-9.-]+\z/`)
      - IP address: valid IPv4 or IPv6 format
      - Minion ID: alphanumeric, underscores, hyphens only
    - Add validation to reject SQL injection patterns
    - Add length limits to all text fields
    - Test validations with edge cases

  - [ ] 2.3 Implement input validation for CVE watchlists
    - Validate package filter is valid regex
    - Test regex compilation before saving
    - Add maximum length limit for regex (500 chars)
    - Validate cron expressions before saving (use `cron_parser` gem)
    - Sanitize package names before passing to Python script
    - Add validation to `CveWatchlist` model

  - [ ] 2.4 Implement input validation for backup configurations
    - Validate repository URLs (allow only SSH URLs)
    - Parse and validate SSH URLs using `URI` module
    - Validate backup paths (reject paths outside allowed directories)
    - Escape all paths before passing to BorgBackup
    - Add validation to `BackupConfiguration` model
    - Test with malicious URL/path inputs

  - [ ] 2.5 Implement input validation for API keys
    - Validate Hetzner API token format (64-character alphanumeric)
    - Validate Proxmox host is valid hostname or IP
    - Validate Proxmox port is valid port number (1-65535)
    - Sanitize all API parameters before making external API calls
    - Add validation to `HetznerApiKey` and `ProxmoxApiKey` models

  - [ ] 2.6 Implement rate limiting per user
    - Extend Rack Attack configuration to track authenticated users
    - Implement per-user rate limits (separate from IP-based limits):
      - Command executions: 10 per minute
      - API key tests: 5 per minute
      - Backup triggers: 2 per minute
      - CVE scans: 1 per minute
    - Add rate limit headers to responses
    - Display rate limit information to users in UI
    - Test rate limiting with rapid requests

  - [ ] 2.7 Ensure security hardening tests pass
    - Run all 5-8 tests written in 2.1
    - Verify input validation works across all models
    - Verify rate limiting enforced correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- 5-8 focused command validation tests pass
- All models have comprehensive input validation
- Dangerous characters and patterns rejected
- Rate limiting per user implemented and tested
- No validation bypasses possible
- All inputs sanitized before external system calls

---

### Task Group 3: Code Refactoring - Service Object Extraction
**Dependencies:** Task Groups 1-2
**Priority:** HIGH
**Estimated Time:** 12-18 hours

#### Objective
Refactor large controller files (20KB+) into service objects to improve maintainability, testability, and separation of concerns.

#### Tasks

- [ ] 3.0 Complete Service Object Extraction
  - [ ] 3.1 Write 4-6 focused tests for service objects
    - Test `SaltService` methods (execute command, sync minions, accept key)
    - Test `HetznerService` methods (power control, snapshots)
    - Test `ProxmoxService` methods (power control, snapshots)
    - Test error handling in service objects

  - [ ] 3.2 Extract `SaltService` from `ServersController`
    - Create `app/services/salt_service.rb`
    - Move methods: `execute_command`, `sync_minions`, `accept_key`, `reject_key`, `get_grains`
    - Keep controller methods thin (single responsibility: params, authorize, call service, respond)
    - Add error handling in service layer
    - Update `ServersController` to use `SaltService`
    - Verify existing functionality unchanged

  - [ ] 3.3 Extract `HetznerService` from `ServersController` and `HetznerApiKeysController`
    - Create `app/services/hetzner_service.rb`
    - Move methods: `list_servers`, `get_server`, `power_on`, `power_off`, `reboot`, `create_snapshot`, `delete_snapshot`
    - Implement connection pooling for API requests
    - Add retry logic for transient failures (3 attempts with exponential backoff)
    - Update controllers to use `HetznerService`
    - Verify existing functionality unchanged

  - [ ] 3.4 Extract `ProxmoxService` from `ServersController` and `ProxmoxApiKeysController`
    - Create `app/services/proxmox_service.rb`
    - Move methods: `list_vms`, `get_vm`, `start`, `stop`, `shutdown`, `reboot`, `create_snapshot`, `rollback_snapshot`, `delete_snapshot`
    - Implement connection pooling for API requests
    - Add retry logic for transient failures
    - Update controllers to use `ProxmoxService`
    - Verify existing functionality unchanged

  - [ ] 3.5 Extract `CveService` from `CveWatchlistsController` and `VulnerabilityAlertsController`
    - Create `app/services/cve_service.rb`
    - Move methods: `scan_watchlist`, `query_cve_database`, `create_alerts`, `send_notifications`
    - Isolate Python subprocess execution in service
    - Add error handling for Python script failures
    - Update controllers to use `CveService`
    - Verify existing functionality unchanged

  - [ ] 3.6 Extract `BackupService` from `BackupConfigurationsController`
    - Create `app/services/backup_service.rb`
    - Move methods: `create_backup`, `prune_backups`, `test_connection`, `initialize_repo`
    - Isolate BorgBackup subprocess execution in service
    - Add error handling for SSH and Borg failures
    - Update controller to use `BackupService`
    - Verify existing functionality unchanged

  - [ ] 3.7 Extract `NotificationService` (Gotify integration)
    - Create `app/services/notification_service.rb`
    - Consolidate all Gotify API calls into service
    - Methods: `send_notification`, `create_application`, `test_connection`
    - Update all code that sends notifications to use service
    - Add error handling for notification failures
    - Verify notifications still work

  - [ ] 3.8 Ensure service object tests pass
    - Run all 4-6 tests written in 3.1
    - Verify service objects work correctly
    - Verify controllers remain thin
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- 4-6 focused service object tests pass
- 7 service objects created and tested
- All large controller files reduced to <10KB
- Controllers contain only: params handling, authorization, service calls, response formatting
- Service objects have single responsibilities
- Existing functionality remains unchanged

---

### Task Group 4: Core Testing - Database Models
**Dependencies:** Task Groups 1-3
**Priority:** HIGH
**Estimated Time:** 15-20 hours

#### Objective
Achieve comprehensive test coverage for all database models including validations, associations, scopes, and business logic methods.

#### Tasks

- [ ] 4.0 Complete Model Testing
  - [ ] 4.1 Test User model (authentication & authorization)
    - Test Devise authentication (email/password validation)
    - Test 2FA setup (OTP secret generation, QR code)
    - Test password strength validation
    - Test associations (commands, tasks created by user)
    - Test `admin?` role check method
    - Target: 6-8 tests covering critical paths

  - [ ] 4.2 Test Server model (managed servers)
    - Test validations (hostname, IP, minion_id uniqueness)
    - Test associations (metrics, commands, groups)
    - Test scopes (online, offline, unreachable)
    - Test status calculation method
    - Test grain data JSON handling
    - Test Hetzner/Proxmox integration fields
    - Target: 8-10 tests

  - [ ] 4.3 Test Command model (execution history)
    - Test validations (command, target presence)
    - Test associations (user, server)
    - Test status transitions (pending → running → completed/failed)
    - Test result JSON storage
    - Test scopes (failed, pending, recent)
    - Target: 6-8 tests

  - [ ] 4.4 Test Task model (automation)
    - Test validations (name uniqueness, command presence, cron expression)
    - Test associations (task_runs)
    - Test enabled/disabled flag
    - Test schedule parsing
    - Test alert threshold logic
    - Target: 6-8 tests

  - [ ] 4.5 Test TaskRun model (execution history)
    - Test validations (task association)
    - Test status transitions
    - Test duration calculation
    - Test associations (task, triggered_by user)
    - Target: 4-6 tests

  - [ ] 4.6 Test CveWatchlist model (vulnerability monitoring)
    - Test validations (name, package_filter, severity)
    - Test regex compilation validation
    - Test cron schedule validation
    - Test associations (vulnerability_alerts, cve_scan_history)
    - Test enabled/disabled flag
    - Target: 6-8 tests

  - [ ] 4.7 Test VulnerabilityAlert model (detected CVEs)
    - Test validations (cve_id, package, severity)
    - Test associations (watchlist, servers)
    - Test status workflow (new → acknowledged → resolved/ignored)
    - Test scopes (active, by_severity)
    - Test CVSS score validation
    - Target: 6-8 tests

  - [ ] 4.8 Test BackupConfiguration model
    - Test validations (repository_url, ssh_key presence)
    - Test encryption (ssh_key, password using attr_encrypted)
    - Test retention policy validation
    - Test cron schedule validation
    - Test associations (backup_history)
    - Target: 6-8 tests

  - [ ] 4.9 Test API key models (HetznerApiKey, ProxmoxApiKey)
    - Test validations (token/credentials format)
    - Test encryption (API tokens)
    - Test enabled/disabled flag
    - Test connection test timestamp tracking
    - Test associations (servers)
    - Target: 4-6 tests per model (8-12 total)

  - [ ] 4.10 Test auxiliary models (Group, ServerMetric, NotificationHistory, etc.)
    - Test Group: validations, server associations
    - Test ServerMetric: validations, time-series data
    - Test NotificationHistory: validations, delivery tracking
    - Test SystemSettings: key-value storage
    - Target: 4-6 tests per model (16-24 total)

  - [ ] 4.11 Ensure model tests pass
    - Run all model tests written in 4.1-4.10
    - Expected total: 60-80 model tests
    - Verify all critical model behaviors covered
    - Do NOT run controller/integration tests at this stage

**Acceptance Criteria:**
- 60-80 model tests written and passing
- All models have validation tests
- All associations tested
- Critical business logic methods tested
- State transitions tested
- Encryption/decryption tested for sensitive fields
- 90%+ coverage for models

---

### Task Group 5: Core Testing - Controllers & Authorization
**Dependencies:** Task Groups 1-4
**Priority:** HIGH
**Estimated Time:** 18-24 hours

#### Objective
Test all controllers for authorization (Pundit policies), response formats, parameter validation, and error handling.

#### Tasks

- [ ] 5.0 Complete Controller Testing
  - [ ] 5.1 Test authentication & authorization (Devise + Pundit)
    - Test login required for all protected routes
    - Test 2FA verification flow
    - Test logout functionality
    - Test password reset flow (if email configured)
    - Test Pundit policy enforcement on all controller actions
    - Target: 6-8 tests

  - [ ] 5.2 Test DashboardController
    - Test index action (authorized user)
    - Test real-time data loading (server stats, recent commands, alerts)
    - Test quick action endpoints (execute command, sync minions)
    - Test unauthorized access denied
    - Target: 4-6 tests

  - [ ] 5.3 Test ServersController
    - Test index (list servers with pagination)
    - Test show (server details)
    - Test new/create (onboarding workflow)
    - Test edit/update (server settings)
    - Test destroy (soft delete)
    - Test bulk actions (group assignment, command execution)
    - Test authorization for each action
    - Test parameter validation
    - Target: 10-12 tests

  - [ ] 5.4 Test CommandsController
    - Test create (execute command)
    - Test index (command history with filters)
    - Test show (command details)
    - Test destroy (delete command)
    - Test parameter validation (command, target)
    - Test authorization
    - Target: 6-8 tests

  - [ ] 5.5 Test TasksController
    - Test index, show, new, create, edit, update, destroy
    - Test enable/disable toggle
    - Test execute_now action (manual trigger)
    - Test task template usage
    - Test parameter validation (name, command, schedule)
    - Test authorization
    - Target: 10-12 tests

  - [ ] 5.6 Test CveWatchlistsController
    - Test CRUD actions (index, show, new, create, edit, update, destroy)
    - Test test_scan action (immediate scan trigger)
    - Test enable/disable toggle
    - Test parameter validation (package filter regex)
    - Test authorization
    - Target: 8-10 tests

  - [ ] 5.7 Test VulnerabilityAlertsController
    - Test index (list alerts with filters)
    - Test show (alert details)
    - Test status update actions (acknowledge, resolve, ignore)
    - Test bulk status updates
    - Test parameter validation
    - Test authorization
    - Target: 8-10 tests

  - [ ] 5.8 Test BackupConfigurationsController
    - Test CRUD actions
    - Test SSH key generation
    - Test connection test action
    - Test manual backup trigger
    - Test parameter validation (repo URL, paths)
    - Test authorization
    - Target: 8-10 tests

  - [ ] 5.9 Test API key controllers (HetznerApiKeysController, ProxmoxApiKeysController)
    - Test CRUD actions for both controllers
    - Test connection test actions
    - Test enable/disable toggles
    - Test server/VM discovery actions
    - Test parameter validation
    - Test authorization
    - Target: 6-8 tests per controller (12-16 total)

  - [ ] 5.10 Test SettingsController (system configuration)
    - Test appearance settings update (logo, company name)
    - Test Gotify configuration
    - Test PyVulnerabilityLookup settings
    - Test maintenance actions (clear commands)
    - Test authorization (admin only)
    - Target: 6-8 tests

  - [ ] 5.11 Ensure controller tests pass
    - Run all controller tests written in 5.1-5.10
    - Expected total: 70-90 controller tests
    - Verify authorization enforced on all actions
    - Verify parameter validation works
    - Do NOT run integration/system tests at this stage

**Acceptance Criteria:**
- 70-90 controller tests written and passing
- All controller actions have authorization tests (Pundit)
- All happy paths tested
- Parameter validation tested
- Error handling tested
- Response formats tested (JSON, HTML, redirects)
- 80%+ coverage for controllers

---

### Task Group 6: Integration Testing - Critical User Workflows
**Dependencies:** Task Groups 1-5
**Priority:** HIGH
**Estimated Time:** 12-16 hours

#### Objective
Test critical multi-step user workflows end-to-end to ensure all components work together correctly.

#### Tasks

- [ ] 6.0 Complete Integration Testing
  - [ ] 6.1 Write 2-4 tests for server onboarding workflow
    - Test complete flow: generate script → minion connects → accept key → server appears
    - Mock Salt API responses
    - Verify server created with correct attributes
    - Verify grains collected

  - [ ] 6.2 Write 2-4 tests for command execution workflow
    - Test complete flow: user submits command → job queued → Salt executes → results stored → UI updates
    - Mock Salt API responses
    - Test both successful and failed command execution
    - Verify Command record created with correct status
    - Verify audit logging

  - [ ] 6.3 Write 2-4 tests for CVE scanning workflow
    - Test complete flow: watchlist created → scan triggered → Python script executes → alerts created → notifications sent
    - Mock PyVulnerabilityLookup responses
    - Mock Gotify notification API
    - Verify VulnerabilityAlert records created
    - Verify scan history recorded

  - [ ] 6.4 Write 2-4 tests for backup execution workflow
    - Test complete flow: configuration created → backup triggered → BorgBackup executes → history recorded
    - Mock SSH connection and BorgBackup commands
    - Test both successful and failed backups
    - Verify backup history recorded
    - Verify failure notifications sent

  - [ ] 6.5 Write 2-4 tests for scheduled task workflow
    - Test complete flow: task created → scheduler triggers → job executes → results recorded
    - Mock Sidekiq Cron scheduling
    - Mock Salt API execution
    - Verify TaskRun created with correct status
    - Test alert threshold triggering

  - [ ] 6.6 Write 2-4 tests for Hetzner cloud integration
    - Test complete flow: API key added → connection tested → servers discovered → power action executed
    - Mock Hetzner Cloud API responses
    - Test power control (start, stop, reboot)
    - Test snapshot creation/deletion
    - Verify status synchronization

  - [ ] 6.7 Write 2-4 tests for Proxmox integration
    - Test complete flow: API key added → connection tested → VMs discovered → power action executed
    - Mock Proxmox API responses
    - Test power control (start, stop, shutdown, reboot)
    - Test snapshot operations (create, rollback, delete)
    - Verify status synchronization

  - [ ] 6.8 Ensure integration tests pass
    - Run all integration tests written in 6.1-6.7
    - Expected total: 14-28 integration tests
    - Verify all workflows complete successfully
    - Do NOT run system tests at this stage

**Acceptance Criteria:**
- 14-28 integration tests written and passing
- All critical workflows tested end-to-end
- External dependencies properly mocked (Salt API, Hetzner, Proxmox, Gotify)
- Error scenarios tested (API failures, timeouts)
- 100% coverage for critical user workflows

---

### Task Group 7: Feature Testing - Server Management & Monitoring
**Dependencies:** Task Groups 1-6
**Priority:** MEDIUM
**Estimated Time:** 8-12 hours

#### Objective
Test server management features including metrics collection, diagnostics, and real-time updates.

#### Tasks

- [ ] 7.0 Complete Server Management Testing
  - [ ] 7.1 Write 2-4 tests for server status tracking
    - Test status calculation (online, offline, unreachable)
    - Test last_seen timestamp updates
    - Test connection error tracking
    - Mock Salt API ping responses

  - [ ] 7.2 Write 2-4 tests for server metrics collection
    - Test ServerMetric creation (CPU, memory, disk, network)
    - Test time-series data storage
    - Test metric aggregation queries
    - Mock grain data collection

  - [ ] 7.3 Write 2-4 tests for server diagnostics
    - Test connection troubleshooting
    - Test Salt version compatibility check
    - Test grain refresh
    - Mock diagnostic command responses

  - [ ] 7.4 Write 2-4 tests for server groups
    - Test group creation/deletion
    - Test adding/removing servers from groups
    - Test bulk actions on group members
    - Test group-based command targeting

  - [ ] 7.5 Write 2-4 tests for real-time updates (Action Cable)
    - Test DashboardChannel subscription
    - Test server status broadcast
    - Test command completion broadcast
    - Test alert notification broadcast
    - Mock WebSocket connections

  - [ ] 7.6 Ensure server management tests pass
    - Run all tests written in 7.1-7.5
    - Expected total: 10-20 tests
    - Verify real-time features work correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- 10-20 server management tests written and passing
- Server status tracking tested
- Metrics collection tested
- Real-time updates tested
- Group management tested

---

### Task Group 8: Feature Testing - CVE Monitoring & Alerts
**Dependencies:** Task Groups 1-6
**Priority:** MEDIUM
**Estimated Time:** 8-12 hours

#### Objective
Test CVE monitoring features including watchlist management, scanning, alert workflow, and notifications.

#### Tasks

- [ ] 8.0 Complete CVE Monitoring Testing
  - [ ] 8.1 Write 2-4 tests for watchlist validation
    - Test package filter regex validation
    - Test regex compilation errors handled gracefully
    - Test severity threshold validation
    - Test cron schedule validation

  - [ ] 8.2 Write 2-4 tests for CVE scanning process
    - Test Python script invocation
    - Test result parsing (JSON response)
    - Test severity filtering
    - Test error handling (script failure, timeout)
    - Mock Python subprocess execution

  - [ ] 8.3 Write 2-4 tests for alert creation logic
    - Test alert deduplication (don't create duplicate alerts for same CVE)
    - Test server association (match CVE to affected servers by package)
    - Test alert status initialization (new)
    - Mock package data from servers

  - [ ] 8.4 Write 2-4 tests for alert workflow
    - Test status transitions (new → acknowledged → resolved/ignored)
    - Test bulk status updates
    - Test status change audit trail (user, timestamp)
    - Test filtering by status and severity

  - [ ] 8.5 Write 2-4 tests for CVE notifications
    - Test Gotify notification creation on new alerts
    - Test notification priority based on severity
    - Test notification content includes CVE details
    - Test notification failure handling
    - Mock Gotify API

  - [ ] 8.6 Write 2-4 tests for scan history
    - Test scan execution recording
    - Test scan error logging
    - Test scan statistics (alert count, duration)
    - Test retention policy

  - [ ] 8.7 Ensure CVE monitoring tests pass
    - Run all tests written in 8.1-8.6
    - Expected total: 12-24 tests
    - Verify scanning and alerting work correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- 12-24 CVE monitoring tests written and passing
- Watchlist validation tested
- Scanning process tested with mocked Python script
- Alert workflow tested
- Notifications tested with mocked Gotify API
- Error handling tested

---

### Task Group 9: Feature Testing - Tasks & Backups
**Dependencies:** Task Groups 1-6
**Priority:** MEDIUM
**Estimated Time:** 8-12 hours

#### Objective
Test task automation and backup management features including scheduling, execution, and error handling.

#### Tasks

- [ ] 9.0 Complete Tasks & Backups Testing
  - [ ] 9.1 Write 2-4 tests for task scheduling
    - Test cron expression parsing
    - Test schedule validation
    - Test Sidekiq Cron integration
    - Mock scheduled job triggers

  - [ ] 9.2 Write 2-4 tests for task execution
    - Test manual task execution (execute_now)
    - Test scheduled task execution
    - Test task run creation
    - Test output capture
    - Mock Salt API command execution

  - [ ] 9.3 Write 2-4 tests for task templates
    - Test template library (updates, maintenance, custom)
    - Test creating task from template
    - Test template field pre-population
    - Test template categorization

  - [ ] 9.4 Write 2-4 tests for task alerting
    - Test consecutive failure threshold detection
    - Test duration threshold detection
    - Test alert notification sending
    - Test auto-resolution on successful run

  - [ ] 9.5 Write 2-4 tests for backup configuration
    - Test SSH URL validation
    - Test path validation (reject dangerous paths)
    - Test SSH key generation (RSA 4096-bit)
    - Test retention policy validation

  - [ ] 9.6 Write 2-4 tests for backup execution
    - Test connection test (SSH + Borg)
    - Test repository initialization
    - Test archive creation
    - Test pruning based on retention policy
    - Mock SSH and BorgBackup commands

  - [ ] 9.7 Write 2-4 tests for backup error handling
    - Test SSH connection failures
    - Test Borg command failures
    - Test disk space errors
    - Test notification on failure
    - Mock error scenarios

  - [ ] 9.8 Ensure tasks & backups tests pass
    - Run all tests written in 9.1-9.7
    - Expected total: 14-28 tests
    - Verify scheduling and execution work correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- 14-28 tasks and backups tests written and passing
- Task scheduling tested with mocked Sidekiq Cron
- Task execution tested with mocked Salt API
- Backup operations tested with mocked SSH/Borg
- Error handling tested for all failure scenarios
- Alert notifications tested

---

### Task Group 10: System Testing - End-to-End Browser Tests
**Dependencies:** Task Groups 1-9
**Priority:** MEDIUM
**Estimated Time:** 10-15 hours

#### Objective
Perform browser-based end-to-end testing of critical user interactions using system tests (Capybara).

#### Tasks

- [ ] 10.0 Complete System Testing
  - [ ] 10.1 Write 2-3 system tests for authentication flow
    - Test user login with email/password
    - Test 2FA setup (QR code display, OTP entry)
    - Test 2FA login flow (OTP verification)
    - Test logout
    - Use Capybara for browser automation

  - [ ] 10.2 Write 2-3 system tests for dashboard interactions
    - Test dashboard loads with all widgets
    - Test quick action execution (execute command form)
    - Test real-time updates appear (use JavaScript driver)
    - Test failed commands widget clear action

  - [ ] 10.3 Write 2-3 system tests for server management
    - Test server list pagination and filtering
    - Test server detail view loads correctly
    - Test executing command on specific server
    - Test server onboarding flow (accept key)

  - [ ] 10.4 Write 2-3 system tests for task management
    - Test creating task from template
    - Test editing task schedule
    - Test manual task execution (execute now button)
    - Test viewing task run history

  - [ ] 10.5 Write 2-3 system tests for CVE alerts
    - Test viewing vulnerability alerts list
    - Test filtering alerts by severity
    - Test changing alert status (acknowledge, resolve)
    - Test bulk status update

  - [ ] 10.6 Write 2-3 system tests for cloud provider integration
    - Test adding Hetzner API key
    - Test testing Hetzner connection
    - Test executing power action (mock API response)
    - Test creating snapshot (mock API response)

  - [ ] 10.7 Write 2-3 system tests for settings and configuration
    - Test updating appearance settings (logo upload)
    - Test configuring Gotify integration
    - Test testing Gotify connection
    - Test maintenance actions (clear failed commands)

  - [ ] 10.8 Ensure system tests pass
    - Run all system tests written in 10.1-10.7
    - Expected total: 14-21 system tests
    - Verify all UI interactions work in browser
    - Test with JavaScript-enabled driver (Selenium or Cuprite)

**Acceptance Criteria:**
- 14-21 system tests written and passing
- Authentication flow tested end-to-end
- All major user workflows tested in browser
- JavaScript interactions tested (real-time updates, forms)
- Tests pass in headless browser

---

### Task Group 11: Test Coverage Analysis & Gap Filling
**Dependencies:** Task Groups 1-10
**Priority:** MEDIUM
**Estimated Time:** 6-10 hours

#### Objective
Review test coverage metrics, identify critical gaps, and write strategic tests to achieve 80%+ overall coverage.

#### Tasks

- [ ] 11.0 Complete Test Coverage Analysis
  - [ ] 11.1 Review existing test coverage
    - Run SimpleCov: `COVERAGE=true rails test`
    - Generate coverage report in `coverage/index.html`
    - Review coverage by file and directory
    - Expected existing coverage: approximately 180-280 tests from Groups 1-10
    - Identify files with <80% coverage
    - Identify critical paths with no coverage

  - [ ] 11.2 Analyze coverage gaps for Veracity platform only
    - Review models with <90% coverage
    - Review controllers with <80% coverage
    - Review service objects with <80% coverage
    - Review background jobs (Sidekiq) coverage
    - Focus ONLY on Veracity application code, not framework code
    - Prioritize gaps in critical features (command execution, CVE scanning, backups)

  - [ ] 11.3 Write up to 10 strategic tests to fill critical gaps
    - Focus on integration points between components
    - Focus on error handling paths not yet tested
    - Focus on edge cases in critical workflows
    - DO NOT write comprehensive coverage for all scenarios
    - Maximum 10 additional tests total
    - Prioritize business-critical functionality

  - [ ] 11.4 Test background jobs (Sidekiq)
    - If not already covered, write 2-4 tests for:
      - `CveScanJob` (scheduled scan execution)
      - `BorgBackupJob` (scheduled backup execution)
      - `TaskExecutionJob` (task execution)
      - `MetricsCollectionJob` (server metrics)
    - Test retry logic (3 attempts with exponential backoff)
    - Mock external dependencies

  - [ ] 11.5 Test WebSocket channels (Action Cable)
    - If not already covered, write 2-4 tests for:
      - `DashboardChannel` (subscription, broadcast)
      - Test connection authorization
      - Test message broadcasting
      - Mock WebSocket connections

  - [ ] 11.6 Run full test suite and verify coverage goals
    - Run complete test suite: `rails test`
    - Run with coverage: `COVERAGE=true rails test`
    - Expected total tests: approximately 190-300 tests
    - Verify overall coverage: 80%+ (SimpleCov report)
    - Verify model coverage: 90%+
    - Verify controller coverage: 80%+
    - Verify critical workflows: 100%

  - [ ] 11.7 Document test coverage and gaps
    - Create `TEST_COVERAGE.md` report:
      - Overall coverage percentage
      - Coverage by component (models, controllers, services, jobs)
      - Known gaps (non-critical features)
      - Testing strategy and approach
    - Update README with testing instructions
    - Document how to run tests locally

**Acceptance Criteria:**
- SimpleCov coverage report generated
- Overall coverage: 80%+ achieved
- Model coverage: 90%+ achieved
- Controller coverage: 80%+ achieved
- Critical workflows: 100% coverage
- Maximum 10 additional strategic tests written to fill gaps
- Total test count: approximately 190-300 tests
- `TEST_COVERAGE.md` documentation created

---

## Summary Statistics

### Expected Test Counts by Task Group

| Task Group | Focus Area | Est. Tests |
|------------|-----------|------------|
| 1 | Foundation & Critical Fixes | 0 (fixes only) |
| 2 | Security Hardening | 5-8 |
| 3 | Service Object Extraction | 4-6 |
| 4 | Database Models | 60-80 |
| 5 | Controllers & Authorization | 70-90 |
| 6 | Integration Workflows | 14-28 |
| 7 | Server Management | 10-20 |
| 8 | CVE Monitoring | 12-24 |
| 9 | Tasks & Backups | 14-28 |
| 10 | System Tests (Browser) | 14-21 |
| 11 | Coverage Gap Filling | 0-10 |
| **TOTAL** | **All Components** | **~190-300** |

### Coverage Targets

- **Overall:** 80%+ (SimpleCov)
- **Models:** 90%+
- **Controllers:** 80%+
- **Services:** 80%+
- **Jobs:** 80%+
- **Critical Workflows:** 100%

### Timeline Estimate

| Phase | Task Groups | Est. Time |
|-------|-------------|-----------|
| Phase 1: Foundation | 1-3 | 30-45 hours |
| Phase 2: Core Testing | 4-5 | 33-44 hours |
| Phase 3: Integration | 6 | 12-16 hours |
| Phase 4: Feature Testing | 7-9 | 24-36 hours |
| Phase 5: System Testing | 10-11 | 16-25 hours |
| **TOTAL** | **All Phases** | **115-166 hours** |

## Notes

### Testing Approach

This task breakdown follows a **focused, incremental testing strategy**:

1. **Fix critical security issues first** (Groups 1-2) before writing tests
2. **Refactor large files into services** (Group 3) to make code testable
3. **Test from bottom-up** (models → controllers → integration → system)
4. **Write minimal, focused tests** during each group (2-10 tests per group)
5. **Verify tests pass incrementally** (don't run full suite until end)
6. **Fill coverage gaps strategically** (Group 11, max 10 additional tests)

### Critical Success Factors

- **Security audit completed** with all critical vulnerabilities fixed
- **Command injection prevention** implemented and tested
- **Service objects extracted** from large controllers
- **80%+ test coverage** achieved across the platform
- **All critical workflows** have 100% test coverage
- **SimpleCov report** generated and documented

### Maintenance

After achieving 80%+ coverage, maintain coverage by:

- Running tests on every commit (CI/CD)
- Requiring tests for new features
- Monitoring coverage metrics
- Updating tests when refactoring
- Running security audits monthly (Brakeman, bundler-audit)

---

**Document Version:** 1.0
**Created:** 2025-11-19
**Status:** Ready for Implementation
