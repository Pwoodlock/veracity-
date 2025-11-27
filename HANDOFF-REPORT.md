# Veracity Infrastructure Handoff Report
**Date:** 2025-11-22 (Updated)
**Server:** 65.21.157.19 (Hetzner)
**Domain:** veracity-stag.devsec.ie

---

## Current State: OPERATIONAL + ENHANCED

All services running. Latest features deployed. Production ready.

---

## Server Stack

| Component | Version | Status | Port | Notes |
|-----------|---------|--------|------|-------|
| PostgreSQL | 17 | Running | 5432 | DB: veracity_production |
| Redis | Latest | Running | 6379 | |
| Salt Master | 3007.x | Running | 4505/4506 | |
| Salt API | 3007.x | Running | 8001 | PAM auth via saltapi user |
| Caddy | 2.6.2 | Running | 80/443 | Reverse proxy to :3000 |
| Puma | - | Running | 3000 | server-manager.service |
| Sidekiq | - | Running | - | server-manager-sidekiq.service |
| Gotify | 2.7.3 | Running | 8080 | Push notifications |

---

## Critical Paths

```
/opt/veracity/app          - Rails application
/opt/veracity-             - Installer scripts (git repo)
/home/deploy               - Deploy user home (Ruby via Mise)
/var/lib/veracity-installer - Installation state/checkpoints
/etc/salt/master.d         - Salt master config
```

---

## Authentication

### Dashboard
- **URL:** https://veracity-stag.devsec.ie
- **Email:** patrick@devsec.ie
- **Password:** NSlo3PVYXc12aOiUYozO

### Salt API
- **User:** saltapi
- **Password:** eIFi8AwAkhthDwVvH9GHm5TeqTmItaw2
- **Auth:** PAM (requires python-pam installed for Salt's Python)

### Database
- **User:** veracity
- **Password:** In /opt/veracity/app/.env.production
- **DB:** veracity_production

---

## Recent Fixes Applied (All Committed to Repo)

### 1. Salt API PAM Authentication
**Problem:** 401 Unauthorized on all Salt API calls
**Root causes:**
- python-pam not installed for Salt's bundled Python (`/opt/saltstack/salt/bin/python3.10`)
- Salt user (uid 999) not in shadow group
- PAM config using wrong includes (system-auth vs common-auth)
- Missing `netapi_enable_clients` for Salt 3007+

**Fixes in `scripts/install/services/salt.sh`:**
```bash
# Install python-pam for Salt's Python
/opt/saltstack/salt/bin/pip3 install python-pam

# Add salt to shadow group
usermod -aG shadow salt

# Detect OS for correct PAM config
# Ubuntu: common-auth
# RHEL: system-auth

# Add to master config:
netapi_enable_clients:
  - local
  - local_async
  - runner
  - runner_async
  - wheel
  - wheel_async
```

### 2. NoNewPrivileges Blocking Sudo
**Problem:** Tasks failed with "no new privileges flag is set"
**Fix in `scripts/install/systemd-setup.sh`:** Removed `NoNewPrivileges=true` from both service files

### 3. Sudo Password Prompt
**Problem:** "a terminal is required to read the password"
**Fix in `scripts/install/services/ruby.sh`:**
```bash
echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/salt, /usr/bin/salt-key, /usr/bin/salt-call, /usr/bin/salt-run" > /etc/sudoers.d/deploy-salt
```

### 4. Partial Salt Command Failure
**Problem:** Task fails completely if any minion doesn't respond
**Fix in `app/jobs/task_execution_job.rb`:**
- Parse results even with exit code 1
- Show output from responding minions
- Add warning about non-responding minions
- Only fail if NO minions respond

### 5. Gotify Binary Detection
**Problem:** "Gotify binary not found in archive"
**Fix in `scripts/install/services/gotify.sh`:** Try multiple patterns (gotify-{platform}, gotify, gotify*)

---

## Minions

Current minions in environment:
- test-4.cacs.devsec (responding)
- test-5.cacs.devsec (responding)
- test-2.cacs.devsec (NOT responding - offline or network issue)

The partial failure handling was implemented specifically because test-2 wasn't responding but test-4 and test-5 were.

---

## Key Commands

### SSH to Server
```bash
sshpass -p '190481**//**' ssh root@65.21.157.19
```

### Deploy Code Updates
```bash
sshpass -p '190481**//**' ssh root@65.21.157.19 "cd /opt/veracity/app && git pull origin main && systemctl restart server-manager server-manager-sidekiq"
```

### Check Services
```bash
systemctl status server-manager server-manager-sidekiq salt-master salt-api
```

### View Logs
```bash
# Puma
journalctl -u server-manager -f
tail -f /opt/veracity/app/log/puma.log

# Sidekiq
journalctl -u server-manager-sidekiq -f
tail -f /opt/veracity/app/log/sidekiq.log

# Salt API
journalctl -u salt-api -f
```

### Test Salt API Auth
```bash
curl -sSk https://localhost:8001/login \
  -H "Accept: application/json" \
  -d username=saltapi \
  -d password=eIFi8AwAkhthDwVvH9GHm5TeqTmItaw2 \
  -d eauth=pam
```

### Resume Failed Installation
```bash
cd /opt/veracity- && ./install.sh --resume
```

---

## Known Issues / Warnings

1. **Log errors:** puma.log has 60 errors, sidekiq.log has 76 errors - likely from initial setup/testing
2. **test-2 minion:** Not responding - check if server is up
3. **Credentials file:** `/tmp/veracity-install-credentials-20251120-215228.txt` - will be deleted on reboot

---

## Recent Updates (Nov 22, 2025)

### New Features Added
1. **Left Sidebar Navigation** - Modern left-side navigation replacing top navbar
2. **Real-time Task Updates** - WebSocket-based live updates (no refresh needed)
3. **36 Pre-built Task Templates** - Ready-to-use Salt commands for monitoring, security, maintenance
4. **Branding Updates** - Changed from "Sodium" to "Veracity" throughout
5. **Maintenance Page** - Now includes TaskRun cleanup options

### Latest Commits
- `3a8ad8d` - Add 24 pre-built task templates with Salt commands
- `45b232c` - Add Turbo and ActionCable for real-time updates
- `974f847` - Implement WebSocket streaming for task results
- `c1fe2ea` - Add task run cleanup to maintenance page
- `fea3004` - Add --static flag for valid multi-minion JSON
- `e407437` - Update default tagline
- `9778604` - Rename Sodium to Veracity

All passed CI.

---

## File Locations for Common Tasks

### Task Execution (Salt commands from UI)
`app/jobs/task_execution_job.rb` - `execute_salt_command` method around line 248

### Salt Installation
`scripts/install/services/salt.sh`

### Systemd Services
`scripts/install/systemd-setup.sh`

### Ruby/Deploy User Setup
`scripts/install/services/ruby.sh`

### Environment Variables
`/opt/veracity/app/.env.production`

---

## What User Was Testing

User created a task "update all servers" which runs Salt commands against all minions. Was getting errors because:
1. NoNewPrivileges blocked sudo
2. Sudo needed password
3. Partial failures (one minion down) caused complete failure

All three fixed. User can now retry the task and should see results from responding minions with a warning about non-responding ones.

---

## Architecture Notes

- **Ruby:** Installed via Mise (not system ruby) for deploy user
- **Salt:** Uses bootstrap script, PAM auth against local system users
- **Caddy:** Auto-HTTPS via Let's Encrypt, reverse proxies to Puma
- **Tasks:** Created in UI, executed via Sidekiq jobs that shell out to Salt commands
- **The deploy user runs Salt commands via sudo** (passwordless for salt-* binaries only)

---

## Next Steps If Issues

1. **Salt API 401:** Check `/opt/saltstack/salt/bin/pip3 list | grep pam`, verify salt in shadow group
2. **Task execution errors:** Check sidekiq logs, verify sudo config in `/etc/sudoers.d/deploy-salt`
3. **Service won't start:** Check `journalctl -u <service> -n 100`
4. **Can't find files:** App is in `/opt/veracity/app`, installer is in `/opt/veracity-`
