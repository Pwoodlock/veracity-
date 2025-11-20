# Comprehensive Validation Command for Veracity

Run this validation to ensure Veracity is working correctly. This tests code quality, service connectivity, and end-to-end workflows.

## Instructions

Execute each phase in order. Stop and fix issues before proceeding to the next phase.

---

## Phase 1: Code Quality

### 1.1 RuboCop - Code Style
```bash
cd /home/patrick/Projects/veracity
bundle exec rubocop --format progress
```
**Expected:** No offenses detected (or only minor style warnings)

### 1.2 Brakeman - Security Scan
```bash
cd /home/patrick/Projects/veracity
bundle exec brakeman -q --no-pager
```
**Expected:** No security warnings (0 warnings found)

---

## Phase 2: Service Connectivity (Local Development)

### 2.1 PostgreSQL Connection
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"
```
**Expected:** No errors, returns successfully

### 2.2 Redis Connection
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "Redis.new.ping"
```
**Expected:** Returns "PONG"

### 2.3 Rails Environment
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "puts Rails.env"
```
**Expected:** Returns "development" or "production"

---

## Phase 3: Database Integrity

### 3.1 Migrations Status
```bash
cd /home/patrick/Projects/veracity
bundle exec rails db:migrate:status
```
**Expected:** All migrations show "up" status

### 3.2 Schema Load Test
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "Server.count; User.count; Command.count"
```
**Expected:** No errors, returns counts

### 3.3 Model Validations
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  # Test core models load correctly
  [Server, User, Command, Group, Task, CveWatchlist, VulnerabilityAlert, BackupConfiguration].each do |model|
    puts \"#{model.name}: #{model.count} records\"
  end
"
```
**Expected:** All models load without error

---

## Phase 4: Salt API Integration (CRITICAL)

This phase tests the Salt API - the integration that was failing.

### 4.1 Salt API Authentication
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  result = SaltService.test_connection
  puts 'Salt API Status: ' + result[:status]
  puts 'API URL: ' + result[:api_url]
  if result[:status] == 'connected'
    puts 'SUCCESS: Salt API is accessible'
  else
    puts 'FAILURE: ' + result[:message].to_s
    exit 1
  end
"
```
**Expected:** Salt API Status: connected

### 4.2 List All Keys (Tests wheel permissions)
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  keys = SaltService.list_keys
  if keys && keys['return']
    data = keys['return'].first['data']['return']
    puts 'Accepted minions: ' + (data['minions'] || []).join(', ')
    puts 'Pending minions: ' + (data['minions_pre'] || []).join(', ')
    puts 'Rejected minions: ' + (data['minions_rejected'] || []).join(', ')
    puts 'SUCCESS: Key listing works'
  else
    puts 'FAILURE: Could not list keys'
    exit 1
  end
"
```
**Expected:** Shows lists of minions (may be empty), no errors

### 4.3 List Pending Keys (THE CRITICAL TEST)
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  pending = SaltService.list_pending_keys
  puts 'Pending keys count: ' + pending.count.to_s
  pending.each do |key|
    puts '  - ' + key[:minion_id] + ' (' + (key[:fingerprint] || 'no fingerprint') + ')'
  end
  puts 'SUCCESS: Pending keys retrieval works'
"
```
**Expected:** Returns array of pending keys (may be empty), no errors

### 4.4 Discover Minions
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  minions = SaltService.discover_all_minions
  puts 'Discovered ' + minions.count.to_s + ' minion(s)'
  minions.each do |m|
    status = m[:online] ? 'ONLINE' : 'OFFLINE'
    puts '  - ' + m[:minion_id] + ': ' + status
  end
  puts 'SUCCESS: Minion discovery works'
"
```
**Expected:** Lists all accepted minions with status

---

## Phase 5: Gotify Notification Integration

### 5.1 Gotify Connection Test
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  begin
    result = GotifyNotificationService.test_connection
    if result[:success]
      puts 'SUCCESS: Gotify connected'
      puts 'Server info: ' + result[:info].to_s
    else
      puts 'WARNING: Gotify not configured or not accessible'
      puts result[:error].to_s
    end
  rescue => e
    puts 'WARNING: Gotify service error - ' + e.message
  end
"
```
**Expected:** Connection successful or clear "not configured" message

---

## Phase 6: Action Cable / WebSocket

### 6.1 Cable Configuration
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  config = Rails.application.config.action_cable
  puts 'Action Cable adapter: ' + ActionCable.server.config.cable[:adapter].to_s
  puts 'SUCCESS: Action Cable configured'
"
```
**Expected:** Shows adapter (async for dev, redis for production)

### 6.2 Broadcast Test
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  Turbo::StreamsChannel.broadcast_replace_to(
    'test_channel',
    target: 'test_target',
    html: '<div>Test</div>'
  )
  puts 'SUCCESS: Turbo Stream broadcast works'
"
```
**Expected:** No errors

---

## Phase 7: Background Jobs (Sidekiq)

### 7.1 Sidekiq Configuration
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  puts 'Sidekiq configured: ' + Sidekiq.server?.to_s
  puts 'Redis URL: ' + Sidekiq.redis { |c| c.connection[:id] rescue 'connected' }
  puts 'SUCCESS: Sidekiq configuration valid'
"
```
**Expected:** Configuration loads without error

---

## Phase 8: End-to-End Workflow Tests

### 8.1 Server Creation Workflow
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  # Test creating a server (simulates accepting a minion key)
  test_server = Server.new(
    hostname: 'test-validate-server',
    minion_id: 'test-validate-' + Time.now.to_i.to_s,
    ip_address: '192.168.1.100',
    status: 'online'
  )

  if test_server.valid?
    puts 'SUCCESS: Server model validation passes'
  else
    puts 'FAILURE: ' + test_server.errors.full_messages.join(', ')
    exit 1
  end

  # Don't actually save - just validate
  puts 'Server creation workflow: OK'
"
```
**Expected:** Server model validates correctly

### 8.2 Command Creation Workflow
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  server = Server.first
  if server
    cmd = Command.new(
      server: server,
      command_type: 'shell',
      command: 'cmd.run',
      arguments: { args: ['echo test'] },
      status: 'pending',
      started_at: Time.current
    )

    if cmd.valid?
      puts 'SUCCESS: Command model validation passes'
    else
      puts 'FAILURE: ' + cmd.errors.full_messages.join(', ')
      exit 1
    end
  else
    puts 'SKIPPED: No servers exist to test command creation'
  end
"
```
**Expected:** Command model validates correctly

### 8.3 Dashboard Stats Calculation
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  stats = {
    total_servers: Server.count,
    online_servers: Server.where(status: 'online').count,
    offline_servers: Server.where(status: 'offline').count,
    commands_today: Command.where('started_at > ?', 24.hours.ago).count
  }

  puts 'Dashboard Stats:'
  stats.each { |k, v| puts '  ' + k.to_s + ': ' + v.to_s }
  puts 'SUCCESS: Dashboard stats calculation works'
"
```
**Expected:** Returns stats without errors

---

## Phase 9: Routes and Controllers

### 9.1 Route Verification
```bash
cd /home/patrick/Projects/veracity
bundle exec rails routes | grep -E "dashboard|onboarding|servers|commands" | head -20
```
**Expected:** Shows routes for main controllers

### 9.2 Controller Loading
```bash
cd /home/patrick/Projects/veracity
bundle exec rails runner "
  controllers = [
    DashboardController,
    OnboardingController,
    ServersController,
    CommandsController,
    TasksController
  ]

  controllers.each do |c|
    puts c.name + ': loaded'
  end
  puts 'SUCCESS: All main controllers load'
"
```
**Expected:** All controllers load without error

---

## Phase 10: Production Server Validation (Run on deployed server)

If running on the production Veracity server, also run these:

### 10.1 System Services
```bash
# Run the existing health check script
sudo /opt/veracity/app/scripts/install/health-check.sh
```
**Expected:** All services running, all connectivity tests pass

### 10.2 Diagnostic Report
```bash
# Run the diagnostic script
sudo /opt/veracity/app/scripts/install/diagnose.sh
```
**Expected:** All checks show green/success

### 10.3 Environment Variables
```bash
# Verify critical env vars are set
grep -E "^(SALT_API|GOTIFY|DATABASE|REDIS|RAILS_)" /opt/veracity/app/.env.production | cut -d'=' -f1
```
**Expected:** All required environment variables present

---

## Summary

If all phases pass:
- Code quality is good
- All services are connected
- Salt API works (pending keys will show!)
- Workflows function correctly
- The application is ready for use

If any phase fails, fix the issue before deploying or continuing. The most critical tests are:
- **Phase 4.3**: List Pending Keys - This is the feature that was broken
- **Phase 2.1-2.2**: Database and Redis - Core services
- **Phase 10.1**: Health Check - All production services

---

## Quick Validation (Minimum Tests)

For a quick check, run just these critical tests:

```bash
cd /home/patrick/Projects/veracity

# 1. Code quality
bundle exec rubocop --format simple | tail -5

# 2. Salt API
bundle exec rails runner "puts SaltService.test_connection[:status]"

# 3. Pending keys (THE FIX)
bundle exec rails runner "puts 'Pending: ' + SaltService.list_pending_keys.count.to_s"

# 4. Database
bundle exec rails runner "puts 'Servers: ' + Server.count.to_s"
```

All should return success/counts without errors.
