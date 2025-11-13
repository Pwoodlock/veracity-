# frozen_string_literal: true

module Settings
  class GotifyController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def index
      # Get settings with source tracking (ENV vs DB)
      @gotify_url = SystemSetting.get_with_source('gotify_url', '')
      @gotify_enabled = SystemSetting.get_with_source('gotify_enabled', false)
      @gotify_app_token = SystemSetting.get_with_source('gotify_app_token', '')
      @app_token_configured = @gotify_app_token[:value].present?

      # Get recent notification history
      @recent_notifications = NotificationHistory.recent.last_n(10)

      # Get statistics
      @statistics = NotificationHistory.statistics
    end

    def update
      begin
        # Check if any ENV overrides are active
        env_overrides = []
        env_overrides << 'URL' if SystemSetting.env_override?('gotify_url')
        env_overrides << 'App Token' if SystemSetting.env_override?('gotify_app_token')
        env_overrides << 'Enabled' if SystemSetting.env_override?('gotify_enabled')

        if env_overrides.any?
          flash[:warning] = "Some settings (#{env_overrides.join(', ')}) are controlled by environment variables and cannot be changed via UI."
          redirect_to settings_gotify_path
          return
        end

        # Update Gotify URL
        if params[:gotify_url].present?
          url = sanitize_url(params[:gotify_url])
          SystemSetting.set('gotify_url', url, 'string')
        end

        # Update app token if provided
        if params[:gotify_app_token].present?
          SystemSetting.set('gotify_app_token', params[:gotify_app_token], 'string')
        end

        # Update enabled status
        enabled = params[:gotify_enabled] == '1' || params[:gotify_enabled] == 'true'
        SystemSetting.set('gotify_enabled', enabled, 'boolean')

        # Test connection if enabled
        if enabled
          test_result = GotifyNotificationService.test_connection

          unless test_result[:success]
            flash[:error] = "Settings saved, but connection test failed: #{test_result[:message]}"
            redirect_to settings_gotify_path
            return
          end
        end

        flash[:notice] = 'Gotify settings updated successfully'
        redirect_to settings_gotify_path
      rescue StandardError => e
        Rails.logger.error "Failed to update Gotify settings: #{e.message}"
        flash[:error] = "Failed to update settings: #{e.message}"
        redirect_to settings_gotify_path
      end
    end

    def test_connection
      begin
        result = GotifyNotificationService.test_connection

        if result[:success]
          render json: {
            success: true,
            message: 'Connection successful! Test notification sent.'
          }
        else
          render json: {
            success: false,
            message: result[:message]
          }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Gotify connection test failed: #{e.message}"
        render json: {
          success: false,
          message: "Connection test failed: #{e.message}"
        }, status: :unprocessable_entity
      end
    end

    private

    def authorize_admin!
      unless current_user.admin?
        flash[:error] = 'You are not authorized to access this page'
        redirect_to root_path
      end
    end

    def sanitize_url(url)
      # Remove trailing slash
      url = url.strip.chomp('/')

      # Add http:// if no protocol specified
      url = "http://#{url}" unless url.start_with?('http://', 'https://')

      # Validate URL format
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        raise ArgumentError, 'Invalid URL format'
      end

      url
    rescue URI::InvalidURIError
      raise ArgumentError, 'Invalid URL format'
    end
  end
end
