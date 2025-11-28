# Agent Handoff Document

## Current Issue: Salt CLI WebSocket Not Connecting

The Salt CLI feature was just implemented but the WebSocket connection is stuck on "Connecting..." and never establishes. The terminal UI loads but ActionCable doesn't connect.

### Symptoms
- Salt CLI page loads at `/admin/salt_cli`
- Terminal UI renders with xterm.js
- Connection status shows "Connecting..." indefinitely
- No WebSocket connection established

### Likely Causes to Investigate
1. **ActionCable configuration** - May need Redis or async adapter configured
2. **Caddy WebSocket proxying** - May not be forwarding `/cable` endpoint correctly
3. **SaltCliChannel authentication** - Channel may be rejecting connection
4. **Missing ActionCable routes or configuration**

---

## Server Details

- **IP**: 46.224.101.253
- **SSH User**: root
- **SSH Password**: `190481**//**`
- **Domain**: veracity-stag.devsec.ie
- **App Location**: `/opt/veracity/app`
- **Service Name**: `server-manager.service` (Puma)
- **Sidekiq Service**: `server-manager-sidekiq.service`

### SSH Command
```bash
sshpass -p '190481**//**' ssh root@46.224.101.253
```

---

## Salt CLI Feature Files

All files were created in this session and are committed to `main`:

### Backend
- **Model**: `app/models/salt_cli_command.rb` - Stores command history
- **Controller**: `app/controllers/admin/salt_cli_controller.rb` - Admin-only, handles CRUD
- **Channel**: `app/channels/salt_cli_channel.rb` - ActionCable channel for WebSocket
- **Job**: `app/jobs/salt_cli_execution_job.rb` - Background job runs Salt commands via PTY
- **Migration**: `db/migrate/20251128211952_create_salt_cli_commands.rb` - Already applied on server

### Frontend
- **Terminal View**: `app/views/admin/salt_cli/index.html.erb` - xterm.js terminal
- **History View**: `app/views/admin/salt_cli/history.html.erb` - Command audit log

### Routes (in `config/routes.rb`)
```ruby
namespace :admin do
  get 'salt_cli' => 'salt_cli#index', as: :salt_cli
  get 'salt_cli/history' => 'salt_cli#history', as: :salt_cli_history
  post 'salt_cli/execute' => 'salt_cli#execute', as: :salt_cli_execute
  get 'salt_cli/command/:id' => 'salt_cli#show_command', as: :salt_cli_show_command
  delete 'salt_cli/command/:id' => 'salt_cli#destroy_command', as: :salt_cli_command
  delete 'salt_cli/history' => 'salt_cli#clear_history', as: :salt_cli_clear_history
end
```

### Sidebar Navigation
- Added to `app/views/shared/_sidebar.html.erb` in the Admin section

---

## Key Code Sections

### SaltCliChannel (`app/channels/salt_cli_channel.rb`)
```ruby
class SaltCliChannel < ApplicationCable::Channel
  def subscribed
    # Verify admin access
    unless current_user&.admin?
      reject
      return
    end
    stream_from "salt_cli_#{current_user.id}"
  end

  def execute(data)
    command = data['command']
    return unless command.present?

    salt_command = SaltCliCommand.create!(
      user: current_user,
      command: command,
      status: 'pending'
    )

    ActionCable.server.broadcast("salt_cli_#{current_user.id}", {
      type: 'command_received',
      command_id: salt_command.id
    })

    SaltCliExecutionJob.perform_later(salt_command.id, current_user.id)
  end
end
```

### Frontend WebSocket Connection (in index.html.erb)
```javascript
import { createConsumer } from 'https://cdn.jsdelivr.net/npm/@rails/actioncable@7.1.3/src/index.js'

const cable = createConsumer();
const channel = cable.subscriptions.create("SaltCliChannel", {
  connected() {
    updateConnectionStatus('connected');
    writePrompt();
  },
  disconnected() {
    updateConnectionStatus('disconnected');
  },
  received(data) {
    handleMessage(data);
  }
});
```

---

## Configuration Files to Check

### ActionCable Config
- `config/cable.yml` - Check adapter (async vs redis)
- `config/environments/production.rb` - Check `config.action_cable` settings

### Caddy Config (on server)
- `/etc/caddy/Caddyfile` - May need WebSocket upgrade headers for `/cable`

### Application Cable
- `app/channels/application_cable/connection.rb` - User authentication for channels
- `app/channels/application_cable/channel.rb` - Base channel class

---

## Commands for Debugging

### Check Rails logs
```bash
sshpass -p '190481**//**' ssh root@46.224.101.253 "tail -100 /opt/veracity/app/log/puma.log"
```

### Check if ActionCable is mounted
```bash
grep -r "ActionCable" config/routes.rb
# Should show: mount ActionCable.server => '/cable'
```

### Test WebSocket endpoint directly
```bash
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" https://veracity-stag.devsec.ie/cable
```

### Check Caddy logs
```bash
sshpass -p '190481**//**' ssh root@46.224.101.253 "journalctl -u caddy -n 50 --no-pager"
```

### Restart services
```bash
sshpass -p '190481**//**' ssh root@46.224.101.253 "systemctl restart server-manager.service"
```

---

## Project Stack

- **Ruby**: 3.3.6 (via Mise)
- **Rails**: 8.0
- **Node**: 24 (via Mise)
- **Database**: SQLite (production)
- **CSS**: Tailwind CSS + DaisyUI
- **Web Server**: Caddy (HTTPS/reverse proxy)
- **Background Jobs**: Sidekiq
- **Real-time**: ActionCable (WebSocket)
- **Terminal**: xterm.js 5.3.0
- **Salt**: SaltStack 3007

---

## Git Status

- **Branch**: main
- **Remote**: https://github.com/Pwoodlock/veracity-.git
- **Latest commits**:
  - `4fd868a` fix(salt-cli): use correct sidebar layout partial
  - `7d5ce9a` feat(admin): add Salt Master CLI with full terminal interface
  - `c6c66f9` docs: add DaisyUI to software stack

---

## What Was Working Before This Session

- Dashboard with server monitoring
- User management (admin only)
- Salt API integration for server commands
- Onboarding flow for new minions
- Tasks system
- CVE monitoring
- Gotify push notifications
- Hetzner/Proxmox integrations

---

## Next Steps

1. **Debug WebSocket connection** - Check browser console for errors
2. **Verify ActionCable config** - Ensure proper adapter and allowed origins
3. **Check Caddy WebSocket support** - May need explicit WebSocket upgrade config
4. **Test ApplicationCable::Connection** - Ensure `current_user` is properly set
5. **Check CORS/CSP headers** - May be blocking WebSocket

---

## Additional Notes

- The Salt CLI should allow running `salt`, `salt-key`, `salt-run`, `salt-call` commands
- Commands execute via PTY for proper terminal output with colors
- All commands are logged to `salt_cli_commands` table for audit
- Only admin users have access to this feature
