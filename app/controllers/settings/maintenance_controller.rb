# frozen_string_literal: true

module Settings
  class MaintenanceController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def index
      # Get counts for display
      @failed_commands_count = Command.where('started_at > ?', 7.days.ago)
                                      .where(status: %w[failed timeout])
                                      .count

      @old_commands_count = Command.where('started_at < ?', 30.days.ago).count

      @total_commands = Command.count
    end

    def clear_failed_commands
      deleted_count = Command.where('started_at > ?', 7.days.ago)
                             .where(status: %w[failed timeout])
                             .delete_all

      Rails.logger.info "[MAINTENANCE] User #{current_user.email} deleted #{deleted_count} failed commands"
      flash[:success] = "✓ Cleared #{deleted_count} failed command#{deleted_count == 1 ? '' : 's'}"
      redirect_to settings_maintenance_path
    end

    def clear_old_commands
      deleted_count = Command.where('started_at < ?', 30.days.ago).delete_all

      Rails.logger.info "[MAINTENANCE] User #{current_user.email} deleted #{deleted_count} old commands (30+ days)"
      flash[:success] = "✓ Cleared #{deleted_count} command#{deleted_count == 1 ? '' : 's'} older than 30 days"
      redirect_to settings_maintenance_path
    end

  end
end
