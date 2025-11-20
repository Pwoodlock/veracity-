# ACTIVE ISSUE: Pending Minion Keys Not Showing on Onboarding Page

## Problem Description
When a new Salt minion is installed on a server, the pending key does NOT appear on the Onboarding page (`/onboarding`) in Veracity. Users cannot accept the minion key because they cannot see it.

## Current Status
- **Symptom**: Pending keys list is empty on onboarding page
- **Expected**: New minion keys should appear in the "Pending Minion Keys" section
- **Impact**: CRITICAL - Users cannot onboard new servers

## Root Cause Investigation

### What We Know
1. The `OnboardingController#index` calls `SaltService.list_pending_keys`
2. This method fetches from Salt API at `http://localhost:8001` (configurable via `SALT_API_URL`)
3. The call may be failing silently and returning an empty array

### Code Locations
- **Onboarding Controller**: `app/controllers/onboarding_controller.rb:135-147` (`load_pending_keys` method)
- **Salt Service**: `app/services/salt_service.rb:477-499` (`list_pending_keys` method)
- **Onboarding View**: `app/views/onboarding/_pending_keys.html.erb`

### Salt Service list_pending_keys Method
```ruby
def list_pending_keys
  Rails.logger.info "Fetching pending minion keys"

  keys_response = list_keys
  return [] unless keys_response && keys_response['return']

  data = keys_response['return'].first['data']
  pending_keys = data['return']['minions_pre'] || []

  Rails.logger.info "Found #{pending_keys.count} pending keys"

  # Get fingerprints for each pending key
  pending_keys.map do |minion_id|
    {
      minion_id: minion_id,
      fingerprint: get_key_fingerprint(minion_id),
      status: 'pending'
    }
  end
rescue StandardError => e
  Rails.logger.error "Error listing pending keys: #{e.message}"
  []
end
```

## Diagnostic Commands to Run on Production Server

```bash
# 1. Check if Salt API is running
sudo systemctl status salt-api

# 2. Check if Salt Master is running
sudo systemctl status salt-master

# 3. Check pending keys directly from Salt (bypass Veracity)
sudo salt-key -L

# 4. Check Rails logs for Salt API errors
sudo tail -100 /opt/veracity/app/log/production.log | grep -i "salt\|pending\|key"

# 5. Test Salt API authentication manually
# Replace YOUR_SALT_API_PASSWORD with actual password from /root/veracity-install-credentials.txt
curl -sk https://localhost:8001/login \
  -H "Accept: application/json" \
  -d username=saltapi \
  -d password='YOUR_SALT_API_PASSWORD' \
  -d eauth=pam

# 6. Test listing keys via Salt API (after getting token from step 5)
# Replace TOKEN with the token from step 5's response
curl -sk https://localhost:8001/ \
  -H "Accept: application/json" \
  -H "X-Auth-Token: TOKEN" \
  -d client=wheel \
  -d fun=key.list_all

# 7. Check Salt API configuration
cat /etc/salt/master.d/api.conf

# 8. Check if saltapi user exists and has correct permissions
id saltapi
grep saltapi /etc/passwd

# 9. Check Salt API port (should be 8001 based on env var)
sudo netstat -tlnp | grep 8001

# 10. Check environment variables
grep SALT_API /opt/veracity/app/.env.production
```

## Likely Causes

### 1. Salt API Service Not Running
- **Check**: `systemctl status salt-api`
- **Fix**: `sudo systemctl start salt-api && sudo systemctl enable salt-api`

### 2. Wrong Salt API URL/Port
- **Check**: `SALT_API_URL` in `.env.production`
- **Default**: `http://localhost:8001`
- **Note**: Code uses HTTP, but curl test above uses HTTPS - verify which is correct

### 3. Authentication Failure
- **Check**: `SALT_API_USERNAME`, `SALT_API_PASSWORD`, `SALT_API_EAUTH` in `.env.production`
- **Default**: `saltapi`, (generated password), `pam`
- **Fix**: Verify credentials match what's in `/etc/salt/master.d/api.conf`

### 4. PAM Authentication Not Configured
- **Check**: `/etc/salt/master.d/api.conf` should have `external_auth: pam:`
- **Check**: saltapi user must exist in system with correct password

### 5. Permissions Issue
- **Check**: Salt API user needs wheel permissions in `/etc/salt/master.d/api.conf`:
```yaml
external_auth:
  pam:
    saltapi:
      - '@wheel'
      - '@runner'
      - '@jobs'
```

### 6. Redis Not Running (for token caching)
- **Check**: `systemctl status redis`
- **Impact**: Salt API tokens won't cache, causing repeated auth failures

## Related Fix Already Applied

A separate fix was applied to `app/models/server.rb` to broadcast dashboard updates when servers are created/updated/deleted. This fix addresses the SECOND issue (dashboard not updating after key acceptance) but NOT this primary issue of keys not appearing.

### Changes Made to server.rb
```ruby
# Added callbacks:
after_create_commit :broadcast_dashboard_update
after_update_commit :broadcast_dashboard_update, if: :saved_change_to_status?
after_destroy_commit :broadcast_dashboard_update

# Added method:
def broadcast_dashboard_update
  # ... broadcasts stats to dashboard via Turbo Streams
end
```

This change needs to be committed and deployed.

## Next Steps

1. **Run diagnostics** listed above on production server
2. **Identify** which component is failing (Salt API, auth, permissions)
3. **Fix** the root cause
4. **Test** that pending keys appear on onboarding page
5. **Commit** the server.rb broadcast fix
6. **Deploy** all changes to production

## Environment Details
- **Production Server**: Veracity installed at `/opt/veracity/app`
- **Salt API Default Port**: 8001
- **Credentials File**: `/root/veracity-install-credentials.txt`
- **Rails Logs**: `/opt/veracity/app/log/production.log`
- **Cable Config**: Uses Redis in production (`config/cable.yml`)

## Files to Review
- `/opt/veracity/app/.env.production` - Environment variables
- `/etc/salt/master.d/api.conf` - Salt API configuration
- `/etc/salt/master` - Main Salt master config
- `/opt/veracity/app/log/production.log` - Application logs
