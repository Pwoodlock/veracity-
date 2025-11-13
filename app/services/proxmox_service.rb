# frozen_string_literal: true

# Service for Proxmox VM/LXC control operations
# Handles power management, snapshots, and status checks via proxmoxer Python library
class ProxmoxService
  # Path to Python script on Proxmox host
  SCRIPT_PATH = '/usr/local/bin/proxmox_api.py'

  class << self
    # ===== Power Management Methods =====

    # Start a Proxmox VM or LXC container
    def start_vm(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'start_vm')

      if result[:success]
        server.update(
          proxmox_power_state: 'running',
          status: 'online',
          last_seen: Time.current
        )
        create_command_record(server, 'start_vm', result)
      end

      result
    end

    # Stop (force) a Proxmox VM or LXC container
    def stop_vm(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'stop_vm')

      if result[:success]
        server.update(
          proxmox_power_state: 'stopped',
          status: 'offline'
        )
        create_command_record(server, 'stop_vm', result)
      end

      result
    end

    # Shutdown (graceful) a Proxmox VM or LXC container
    def shutdown_vm(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'shutdown_vm')

      if result[:success]
        server.update(
          proxmox_power_state: 'stopped',
          status: 'offline'
        )
        create_command_record(server, 'shutdown_vm', result)
      end

      result
    end

    # Reboot a Proxmox VM or LXC container
    def reboot_vm(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'reboot_vm')

      if result[:success]
        server.update(
          proxmox_power_state: 'running'
        )
        create_command_record(server, 'reboot_vm', result)
      end

      result
    end

    # ===== Status Methods =====

    # Get current VM/LXC status
    def get_vm_status(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'get_vm_status')

      if result[:success] && result[:data]
        # Update server record with latest status
        update_server_from_status(server, result[:data])
      end

      result
    end

    # Refresh VM/LXC info from Proxmox API
    def refresh_vm_info(server)
      result = get_vm_status(server)

      if result[:success] && result[:data]
        create_command_record(server, 'refresh_proxmox_info', result)
      end

      result
    end

    # ===== Snapshot Methods =====

    # List all snapshots for a VM or LXC container
    def list_snapshots(server)
      validate_server!(server)

      result = execute_proxmox_command(server, 'list_snapshots')

      if result[:success]
        create_command_record(server, 'list_snapshots', result)
      end

      result
    end

    # Create a new snapshot
    def create_snapshot(server, snap_name, description = '')
      validate_server!(server)

      result = execute_proxmox_command(server, 'create_snapshot', {
        snap_name: snap_name,
        description: description
      })

      if result[:success]
        create_command_record(server, 'create_snapshot', result.merge(
          snapshot_name: snap_name
        ))
      end

      result
    end

    # Rollback VM/LXC to a snapshot
    def rollback_snapshot(server, snap_name)
      validate_server!(server)

      result = execute_proxmox_command(server, 'rollback_snapshot', {
        snap_name: snap_name
      })

      if result[:success]
        create_command_record(server, 'rollback_snapshot', result.merge(
          snapshot_name: snap_name
        ))
      end

      result
    end

    # Delete a snapshot
    def delete_snapshot(server, snap_name)
      validate_server!(server)

      result = execute_proxmox_command(server, 'delete_snapshot', {
        snap_name: snap_name
      })

      if result[:success]
        create_command_record(server, 'delete_snapshot', result.merge(
          snapshot_name: snap_name
        ))
      end

      result
    end

    # ===== Discovery Methods =====

    # List all VMs and containers on a Proxmox node
    # Takes a ProxmoxApiKey object and node name
    def list_vms(api_key, node_name)
      unless api_key.is_a?(ProxmoxApiKey)
        raise ArgumentError, "Expected ProxmoxApiKey, got #{api_key.class}"
      end

      unless api_key.enabled?
        return {
          success: false,
          error: "API key '#{api_key.name}' is disabled",
          timestamp: Time.current.iso8601
        }
      end

      # Extract short hostname for Proxmox API (e.g., pve-1 from pve-1.fritz.box)
      # Proxmox node names are typically just the short hostname
      proxmox_node = node_name.split('.').first

      # Build command for Python script via Salt
      command = build_python_command('list_vms', {
        api_url: api_key.proxmox_url,
        username: api_key.username,
        token: api_key.api_token,
        node: proxmox_node,
        verify_ssl: api_key.verify_ssl
      })

      # Mark API key as used
      api_key.mark_as_used!

      # Execute via Salt on Proxmox host
      # Use the full hostname as the minion ID (pve-1.fritz.box format)
      minion_id = node_name
      salt_result = SaltService.run_command(minion_id, 'cmd.run', [command], timeout: 30)

      if salt_result[:success]
        parse_json_response(salt_result[:output])
      else
        {
          success: false,
          error: "Salt command failed: #{salt_result[:output]}",
          timestamp: Time.current.iso8601
        }
      end
    rescue StandardError => e
      Rails.logger.error "ProxmoxService list_vms error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: e.message,
        timestamp: Time.current.iso8601
      }
    end

    # Test connection to Proxmox API
    def test_connection(api_key)
      unless api_key.is_a?(ProxmoxApiKey)
        raise ArgumentError, "Expected ProxmoxApiKey, got #{api_key.class}"
      end

      unless api_key.enabled?
        return {
          success: false,
          error: "API key '#{api_key.name}' is disabled",
          timestamp: Time.current.iso8601
        }
      end

      # Build command for Python script via Salt
      command = build_python_command('test_connection', {
        api_url: api_key.proxmox_url,
        username: api_key.username,
        token: api_key.api_token,
        verify_ssl: api_key.verify_ssl
      })

      # Mark API key as used
      api_key.mark_as_used!

      # Extract hostname from URL for minion targeting
      # proxmox_url format: https://pve-1.fritz.box:8006
      minion_id = extract_hostname_from_url(api_key.proxmox_url)

      # Execute via Salt
      salt_result = SaltService.run_command(minion_id, 'cmd.run', [command], timeout: 15)

      if salt_result[:success]
        parse_json_response(salt_result[:output])
      else
        {
          success: false,
          error: "Salt command failed: #{salt_result[:output]}",
          timestamp: Time.current.iso8601
        }
      end
    rescue StandardError => e
      Rails.logger.error "ProxmoxService test_connection error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: e.message,
        timestamp: Time.current.iso8601
      }
    end

    private

    # Execute Proxmox Python script command via Salt
    def execute_proxmox_command(server, command, extra_params = {})
      api_key = server.proxmox_api_key

      # Extract short hostname for Proxmox API (e.g., pve-1 from pve-1.fritz.box)
      # Proxmox node names are typically just the short hostname
      proxmox_node = server.proxmox_node.split('.').first

      # Build command parameters
      params = {
        api_url: api_key.proxmox_url,
        username: api_key.username,
        token: api_key.api_token,
        node: proxmox_node,
        vmid: server.proxmox_vmid,
        vm_type: server.proxmox_type,
        verify_ssl: api_key.verify_ssl
      }.merge(extra_params)

      # Build Python command
      python_cmd = build_python_command(command, params)

      # Mark API key as used
      api_key.mark_as_used!

      # Execute via Salt on Proxmox host (use full hostname as minion ID)
      minion_id = server.proxmox_node
      salt_result = SaltService.run_command(minion_id, 'cmd.run', [python_cmd], timeout: 60)

      if salt_result[:success]
        parse_json_response(salt_result[:output])
      else
        {
          success: false,
          error: "Salt command failed: #{salt_result[:output]}",
          timestamp: Time.current.iso8601
        }
      end
    rescue StandardError => e
      Rails.logger.error "ProxmoxService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: e.message,
        timestamp: Time.current.iso8601
      }
    end

    # Build Python command with proper argument escaping
    def build_python_command(command, params)
      cmd_parts = [
        'python3',
        SCRIPT_PATH,
        command
      ]

      # Add parameters based on command type
      case command
      when 'test_connection'
        cmd_parts += [
          escape_shell_arg(params[:api_url]),
          escape_shell_arg(params[:username]),
          escape_shell_arg(params[:token]),
          params[:verify_ssl] ? 'true' : 'false'
        ]
      when 'list_vms'
        cmd_parts += [
          escape_shell_arg(params[:api_url]),
          escape_shell_arg(params[:username]),
          escape_shell_arg(params[:token]),
          escape_shell_arg(params[:node]),
          params[:verify_ssl] ? 'true' : 'false'
        ]
      when 'get_vm_status', 'start_vm', 'stop_vm', 'shutdown_vm', 'reboot_vm', 'list_snapshots'
        cmd_parts += [
          escape_shell_arg(params[:api_url]),
          escape_shell_arg(params[:username]),
          escape_shell_arg(params[:token]),
          escape_shell_arg(params[:node]),
          params[:vmid].to_s,
          escape_shell_arg(params[:vm_type]),
          params[:verify_ssl] ? 'true' : 'false'
        ]
      when 'create_snapshot'
        cmd_parts += [
          escape_shell_arg(params[:api_url]),
          escape_shell_arg(params[:username]),
          escape_shell_arg(params[:token]),
          escape_shell_arg(params[:node]),
          params[:vmid].to_s,
          escape_shell_arg(params[:vm_type]),
          escape_shell_arg(params[:snap_name]),
          escape_shell_arg(params[:description] || ''),
          params[:verify_ssl] ? 'true' : 'false'
        ]
      when 'rollback_snapshot', 'delete_snapshot'
        cmd_parts += [
          escape_shell_arg(params[:api_url]),
          escape_shell_arg(params[:username]),
          escape_shell_arg(params[:token]),
          escape_shell_arg(params[:node]),
          params[:vmid].to_s,
          escape_shell_arg(params[:vm_type]),
          escape_shell_arg(params[:snap_name]),
          params[:verify_ssl] ? 'true' : 'false'
        ]
      end

      cmd_parts.join(' ')
    end

    # Escape shell argument for safe command execution
    def escape_shell_arg(arg)
      return '""' if arg.nil? || arg.to_s.empty?
      # Use single quotes to prevent shell interpolation
      "'#{arg.to_s.gsub("'", "'\\''")}'"
    end

    # Parse JSON response from Python script
    def parse_json_response(output)
      # Extract JSON from output (in case there's any extra logging)
      json_match = output.match(/\{.*\}/m)
      json_str = json_match ? json_match[0] : output

      JSON.parse(json_str, symbolize_names: true)
    rescue JSON::ParserError => e
      {
        success: false,
        error: "Failed to parse response: #{e.message}",
        raw_output: output,
        timestamp: Time.current.iso8601
      }
    end

    # Validate server has required Proxmox configuration
    def validate_server!(server)
      unless server.proxmox_server?
        raise ArgumentError, "Server #{server.hostname} is not configured as a Proxmox VM/LXC"
      end

      unless server.can_use_proxmox_features?
        raise ArgumentError, "Server #{server.hostname} cannot use Proxmox features (API key disabled or missing)"
      end
    end

    # Update server attributes from Proxmox status data
    def update_server_from_status(server, status_data)
      # status_data format: {vmid:, node:, type:, status:, uptime:, cpus:, memory:, maxmem:, name:}
      updates = {
        proxmox_power_state: status_data[:status],
        last_seen: Time.current
      }

      # Map Proxmox status to server status
      updates[:status] = case status_data[:status]
                        when 'running'
                          'online'
                        when 'stopped', 'paused'
                          'offline'
                        else
                          'unreachable'
                        end

      server.update(updates)
    end

    # Extract hostname from Proxmox URL for minion targeting
    # Examples:
    #   https://pve-1.fritz.box:8006 -> pve-1.fritz.box
    #   http://192.168.1.100:8006 -> 192.168.1.100
    def extract_hostname_from_url(url)
      uri = URI.parse(url)
      uri.host
    rescue URI::InvalidURIError => e
      Rails.logger.error "Invalid Proxmox URL: #{url} - #{e.message}"
      # Fallback: try to extract hostname with regex
      url.gsub(/^https?:\/\//, '').split(':').first
    end

    # Create command record for audit trail
    def create_command_record(server, command_type, result)
      command_description = case command_type
                          when 'start_vm' then 'Proxmox: Start VM/LXC'
                          when 'stop_vm' then 'Proxmox: Stop VM/LXC (Force)'
                          when 'shutdown_vm' then 'Proxmox: Shutdown VM/LXC (Graceful)'
                          when 'reboot_vm' then 'Proxmox: Reboot VM/LXC'
                          when 'refresh_proxmox_info' then 'Proxmox: Refresh VM Info'
                          when 'list_snapshots' then 'Proxmox: List Snapshots'
                          when 'create_snapshot' then "Proxmox: Create Snapshot '#{result[:snapshot_name]}'"
                          when 'rollback_snapshot' then "Proxmox: Rollback to Snapshot '#{result[:snapshot_name]}'"
                          when 'delete_snapshot' then "Proxmox: Delete Snapshot '#{result[:snapshot_name]}'"
                          else
                            "Proxmox: #{command_type.humanize}"
                          end

      Command.create!(
        server: server,
        command_type: command_type,
        command: command_description,
        status: result[:success] ? 'completed' : 'failed',
        output: result[:data] ? JSON.pretty_generate(result[:data]) : result[:message],
        error_output: result[:error],
        started_at: Time.current,
        completed_at: Time.current,
        duration_seconds: 0
      )
    rescue StandardError => e
      Rails.logger.error "Failed to create command record: #{e.message}"
    end
  end
end
