# frozen_string_literal: true

# Background job for executing Salt CLI commands
# Streams output in real-time via ActionCable
class SaltCliExecutionJob < ApplicationJob
  queue_as :default

  # Allowed Salt commands
  ALLOWED_COMMANDS = %w[salt salt-key salt-run salt-call].freeze

  def perform(command_id)
    command_record = SaltCliCommand.find(command_id)
    user = command_record.user

    # Validate command
    base_cmd = command_record.command.split.first
    unless ALLOWED_COMMANDS.include?(base_cmd)
      fail_command(command_record, user, "Invalid command: #{base_cmd}. Allowed: #{ALLOWED_COMMANDS.join(', ')}")
      return
    end

    # Mark as running
    command_record.update!(status: 'running', started_at: Time.current)
    broadcast_to_user(user, {
      type: 'command_started',
      command_id: command_record.id,
      command: command_record.command
    })

    # Execute command
    output = StringIO.new
    exit_status = nil

    begin
      # Use PTY for real terminal output with colors
      require 'pty'
      require 'io/console'

      full_command = build_command(command_record.command)
      Rails.logger.info "SaltCliExecutionJob: Executing '#{full_command}' for user #{user.email}"

      PTY.spawn(full_command) do |stdout, _stdin, pid|
        begin
          stdout.each_char do |char|
            output << char

            # Broadcast character-by-character for real-time feel
            # Buffer small chunks for efficiency
            if output.string.length % 100 == 0 || char == "\n"
              broadcast_to_user(user, {
                type: 'output',
                command_id: command_record.id,
                data: output.string
              })
            end
          end
        rescue Errno::EIO
          # End of output
        end

        # Wait for process to finish
        Process.wait(pid)
        exit_status = $?.exitstatus
      end
    rescue PTY::ChildExited => e
      exit_status = e.status.exitstatus
    rescue => e
      output << "\r\n\e[31mError: #{e.message}\e[0m\r\n"
      exit_status = 1
      Rails.logger.error "SaltCliExecutionJob error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end

    # Final broadcast with complete output
    final_output = output.string
    broadcast_to_user(user, {
      type: 'output',
      command_id: command_record.id,
      data: final_output,
      final: true
    })

    # Update command record
    command_record.update!(
      status: exit_status == 0 ? 'completed' : 'failed',
      output: final_output,
      exit_status: exit_status,
      completed_at: Time.current
    )

    # Broadcast completion
    broadcast_to_user(user, {
      type: 'command_completed',
      command_id: command_record.id,
      exit_status: exit_status,
      duration: command_record.duration
    })
  end

  private

  def build_command(command)
    # Run as deploy user who has passwordless sudo for salt-* commands
    # deploy ALL=(ALL) NOPASSWD: /usr/bin/salt, /usr/bin/salt-key, etc.
    escaped_command = command.gsub("'", "'\\''")
    "sudo -u deploy bash -lc 'sudo #{escaped_command}'"
  end

  def fail_command(command_record, user, message)
    command_record.update!(
      status: 'failed',
      output: "\e[31m#{message}\e[0m",
      exit_status: 1,
      started_at: Time.current,
      completed_at: Time.current
    )

    broadcast_to_user(user, {
      type: 'command_failed',
      command_id: command_record.id,
      error: message
    })
  end

  def broadcast_to_user(user, data)
    ActionCable.server.broadcast("salt_cli_#{user.id}", data)
  end
end
