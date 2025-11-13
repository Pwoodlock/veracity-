#!/bin/bash
#
# Veracity - One-Click Interactive Installer
# Interactive installation script for Veracity Server Manager
#
# Usage: curl -sSL https://raw.githubusercontent.com/Pwoodlock/veracity/main/install.sh | sudo bash
#        or: sudo ./install.sh
#        or: sudo ./install.sh --resume (to resume after fixing errors)
#

# Use safer bash settings but allow error handling
set -uo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
# shellcheck source=scripts/install/lib/common.sh
source "${SCRIPT_DIR}/scripts/install/lib/common.sh"
# shellcheck source=scripts/install/lib/validators.sh
source "${SCRIPT_DIR}/scripts/install/lib/validators.sh"
# shellcheck source=scripts/install/lib/error_handling.sh
source "${SCRIPT_DIR}/scripts/install/lib/error_handling.sh"

#######################################
# Print banner
#######################################
print_banner() {
  clear
  cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║  ██╗   ██╗███████╗██████╗  █████╗  ██████╗██╗████████╗██╗   ║
║  ██║   ██║██╔════╝██╔══██╗██╔══██╗██╔════╝██║╚══██╔══╝╚██╗  ║
║  ██║   ██║█████╗  ██████╔╝███████║██║     ██║   ██║    ╚██╗ ║
║  ╚██╗ ██╔╝██╔══╝  ██╔══██╗██╔══██║██║     ██║   ██║    ██╔╝ ║
║   ╚████╔╝ ███████╗██║  ██║██║  ██║╚██████╗██║   ██║   ██╔╝  ║
║    ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝   ╚═╝   ╚═╝   ║
║                                                              ║
║                    Version 1.0 Installer                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
  echo -e "${CYAN}Welcome to the Veracity automated installer!${NC}"
  echo ""
  echo "This installer will:"
  echo "  • Install all required dependencies"
  echo "  • Configure PostgreSQL, Redis, and SaltStack"
  echo "  • Set up Ruby 3.3.5 and Node.js 18"
  echo "  • Install and configure Caddy with automatic HTTPS"
  echo "  • Deploy the Veracity application"
  echo "  • Create systemd services"
  echo "  • Configure firewall"
  echo ""
  echo -e "${YELLOW}Estimated time: 25-35 minutes${NC}"
  echo ""
}

#######################################
# Collect user input
#######################################
collect_configuration() {
  section "Configuration"

  info "Please provide the following information:"
  echo ""

  # Domain/Host
  while true; do
    RAILS_HOST=$(prompt "Domain or IP address (e.g., sm.example.com)" "$(hostname -I | awk '{print $1}')")
    if validate_domain "${RAILS_HOST}"; then
      break
    fi
  done

  # Protocol
  if confirm "Enable HTTPS with automatic Let's Encrypt certificates?" "y"; then
    RAILS_PROTOCOL="https"
    RAILS_FORCE_SSL="true"
  else
    RAILS_PROTOCOL="http"
    RAILS_FORCE_SSL="false"
    warning "HTTPS disabled - only use for development/testing!"
  fi

  # Admin credentials
  echo ""
  while true; do
    ADMIN_EMAIL=$(prompt "Admin email address")
    if validate_email "${ADMIN_EMAIL}"; then
      break
    fi
  done

  if confirm "Generate secure admin password automatically?" "y"; then
    ADMIN_PASSWORD=$(generate_password 20)
    info "Generated admin password (will be saved to credentials file)"
  else
    while true; do
      ADMIN_PASSWORD=$(prompt_password "Admin password")
      if validate_password_strength "${ADMIN_PASSWORD}"; then
        break
      fi
    done
  fi

  # Database configuration
  echo ""
  info "Database Configuration"
  DB_NAME="server_manager_production"
  DB_USER=$(prompt "Database username" "servermanager")
  DB_PASSWORD=$(generate_password 32)
  DB_HOST="localhost"
  info "Database: ${DB_NAME}, User: ${DB_USER}"

  # Generate secrets
  SECRET_KEY_BASE=$(generate_secret_key_base)
  SALT_API_USER="saltapi"
  SALT_API_PASSWORD=$(generate_password 32)
  SALT_API_URL="http://localhost:8001"
  SALT_API_EAUTH="pam"
  REDIS_URL="redis://localhost:6379/0"

  # All features enabled by default - configure via UI with API keys
  echo ""
  section "Feature Configuration"

  info "All features will be installed and enabled by default:"
  echo "  • Gotify push notifications (Docker-based)"
  echo "  • CVE vulnerability scanning (Python venv)"
  echo "  • Proxmox API support (configure in UI)"
  echo "  • OAuth2/Zitadel SSO ready (configure in UI)"
  echo ""
  info "You can configure API keys and credentials via the web UI after installation"
  echo ""

  # Gotify domain configuration
  echo ""
  while true; do
    GOTIFY_HOST=$(prompt "Gotify domain or subdomain (e.g., gotify.yourserver.ie)")
    if validate_domain "${GOTIFY_HOST}"; then
      break
    fi
  done

  # Gotify - always install
  GOTIFY_ENABLED="true"
  GOTIFY_PORT="8080"
  GOTIFY_ADMIN_USER="admin"
  GOTIFY_ADMIN_PASSWORD=$(generate_password 20)
  GOTIFY_URL="${RAILS_PROTOCOL}://${GOTIFY_HOST}"
  GOTIFY_APP_TOKEN=""  # Will be generated after installation

  # OAuth/Zitadel - prepare for configuration
  OAUTH_ENABLED="false"  # Disabled until configured in UI
  ZITADEL_ISSUER=""
  ZITADEL_CLIENT_ID=""

  # CVE Monitoring - always install
  CVE_ENABLED="true"
  CVE_URL="https://vulnerability.circl.lu"
  CVE_SCHEDULE="0 2 * * *"

  # Timezone
  TZ=$(prompt "Server timezone" "UTC")

  # Build configuration
  INSTALL_URL="${RAILS_PROTOCOL}://${RAILS_HOST}"

  success "Configuration collected successfully!"
}

#######################################
# Confirm installation
#######################################
confirm_installation() {
  section "Installation Summary"

  cat << EOF
Main Domain:     ${RAILS_HOST}
Gotify Domain:   ${GOTIFY_HOST}
Protocol:        ${RAILS_PROTOCOL}
Admin Email:     ${ADMIN_EMAIL}
Database:        ${DB_NAME}
Database User:   ${DB_USER}

Features (All Enabled):
  ✓ Gotify push notifications (${GOTIFY_URL})
  ✓ CVE vulnerability scanning (${CVE_URL})
  ✓ Proxmox API support
  ✓ OAuth2/Zitadel SSO ready

Installation Path: /opt/server-manager
Deploy User:      deploy
Ruby Version:     3.3.5
Node.js Version:  18 LTS
EOF

  echo ""
  if ! confirm "Proceed with installation?" "y"; then
    fatal "Installation cancelled by user"
  fi
}

#######################################
# Install PostgreSQL phase
#######################################
phase_postgresql() {
  validate_phase_prerequisites "PostgreSQL" || return 1
  progress_bar 1 10 "Installing PostgreSQL..."
  source "${SCRIPT_DIR}/scripts/install/services/postgresql.sh"
  setup_postgresql
  add_rollback "Stop PostgreSQL" "systemctl stop postgresql 2>/dev/null"
  add_rollback "Remove PostgreSQL" "apt-get remove -y postgresql* 2>/dev/null || dnf remove -y postgresql* 2>/dev/null"
}

#######################################
# Install Redis phase
#######################################
phase_redis() {
  validate_phase_prerequisites "Redis" || return 1
  progress_bar 2 10 "Installing Redis..."
  source "${SCRIPT_DIR}/scripts/install/services/redis.sh"
  setup_redis
  add_rollback "Stop Redis" "systemctl stop redis-server 2>/dev/null || systemctl stop redis 2>/dev/null"
  add_rollback "Remove Redis" "apt-get remove -y redis* 2>/dev/null || dnf remove -y redis* 2>/dev/null"
}

#######################################
# Install SaltStack phase
#######################################
phase_salt() {
  validate_phase_prerequisites "SaltStack" || return 1
  progress_bar 3 10 "Installing SaltStack..."
  source "${SCRIPT_DIR}/scripts/install/services/salt.sh"
  setup_salt
  add_rollback "Stop Salt services" "systemctl stop salt-master salt-api 2>/dev/null"
  add_rollback "Remove Salt" "apt-get remove -y salt-* 2>/dev/null || dnf remove -y salt-* 2>/dev/null"
}

#######################################
# Install Ruby phase
#######################################
phase_ruby() {
  progress_bar 4 10 "Installing Ruby 3.3.5..."
  source "${SCRIPT_DIR}/scripts/install/services/ruby.sh"
  setup_ruby
  add_rollback "Remove rbenv" "rm -rf /home/deploy/.rbenv 2>/dev/null"
}

#######################################
# Install Node.js phase
#######################################
phase_nodejs() {
  progress_bar 5 10 "Installing Node.js..."
  source "${SCRIPT_DIR}/scripts/install/services/nodejs.sh"
  setup_nodejs
  add_rollback "Remove Node.js" "apt-get remove -y nodejs 2>/dev/null || dnf remove -y nodejs 2>/dev/null"
}

#######################################
# Install Caddy phase
#######################################
phase_caddy() {
  validate_phase_prerequisites "Caddy" || return 1
  progress_bar 6 10 "Installing Caddy..."
  source "${SCRIPT_DIR}/scripts/install/services/caddy.sh"
  setup_caddy
  add_rollback "Stop Caddy" "systemctl stop caddy 2>/dev/null"
  add_rollback "Remove Caddy" "apt-get remove -y caddy 2>/dev/null || dnf remove -y caddy 2>/dev/null"
}

#######################################
# Install Gotify phase
#######################################
phase_gotify() {
  progress_bar 7 10 "Installing Gotify..."
  source "${SCRIPT_DIR}/scripts/install/services/gotify.sh"
  setup_gotify
  add_rollback "Stop Gotify" "docker stop gotify 2>/dev/null && docker rm gotify 2>/dev/null"
}

#######################################
# Install CVE monitoring phase
#######################################
phase_cve() {
  progress_bar 7.5 10 "Installing CVE monitoring..."
  source "${SCRIPT_DIR}/scripts/install/services/cve_monitoring.sh"
  setup_cve_monitoring
  add_rollback "Remove CVE venv" "rm -rf /opt/cve-monitor 2>/dev/null"
}

#######################################
# Setup application phase
#######################################
phase_application() {
  validate_phase_prerequisites "Application" || return 1
  progress_bar 8 10 "Setting up application..."
  source "${SCRIPT_DIR}/scripts/install/app-setup.sh"
  setup_application
  add_rollback "Remove application" "rm -rf /opt/server-manager 2>/dev/null"
  add_rollback "Drop database" "sudo -u postgres psql -c 'DROP DATABASE IF EXISTS ${DB_NAME}' 2>/dev/null"
  add_rollback "Drop database user" "sudo -u postgres psql -c 'DROP USER IF EXISTS ${DB_USER}' 2>/dev/null"
}

#######################################
# Setup systemd services phase
#######################################
phase_systemd() {
  progress_bar 9 10 "Configuring systemd services..."
  source "${SCRIPT_DIR}/scripts/install/systemd-setup.sh"
  setup_systemd
  add_rollback "Stop services" "systemctl stop server-manager server-manager-sidekiq 2>/dev/null"
  add_rollback "Remove service files" "rm -f /etc/systemd/system/server-manager*.service 2>/dev/null"
  add_rollback "Reload systemd" "systemctl daemon-reload 2>/dev/null"
}

#######################################
# Setup firewall phase
#######################################
phase_firewall() {
  progress_bar 10 10 "Configuring firewall..."
  source "${SCRIPT_DIR}/scripts/install/firewall.sh"
  setup_firewall
}

#######################################
# Health checks phase
#######################################
phase_health_checks() {
  echo ""
  source "${SCRIPT_DIR}/scripts/install/health-check.sh"
  run_health_checks
}

#######################################
# Run installation steps
#######################################
run_installation() {
  local start_time
  start_time=$(date +%s)

  # Prerequisites
  run_phase "Prerequisites" check_prerequisites "required" || return 1

  # Export configuration
  export OS_ID OS_NAME OS_VERSION
  export DB_NAME DB_USER DB_PASSWORD DB_HOST
  export SALT_API_USER SALT_API_PASSWORD SALT_API_URL SALT_API_EAUTH
  export SECRET_KEY_BASE REDIS_URL
  export ADMIN_EMAIL ADMIN_PASSWORD
  export RAILS_HOST RAILS_PROTOCOL RAILS_FORCE_SSL RAILS_LOG_LEVEL="info" RAILS_MAX_THREADS="10"
  export GOTIFY_ENABLED GOTIFY_PORT GOTIFY_ADMIN_USER GOTIFY_ADMIN_PASSWORD GOTIFY_URL GOTIFY_APP_TOKEN GOTIFY_HOST
  export OAUTH_ENABLED ZITADEL_ISSUER ZITADEL_CLIENT_ID
  export CVE_ENABLED CVE_URL CVE_SCHEDULE
  export TZ INSTALL_URL WEB_CONCURRENCY="2"

  # Update system
  run_phase "SystemUpdate" update_system_packages "required" || return 1

  # Install services with error handling
  run_phase "PostgreSQL" phase_postgresql "required" || return 1
  run_phase "Redis" phase_redis "required" || return 1
  run_phase "SaltStack" phase_salt "required" || return 1
  run_phase "Ruby" phase_ruby "required" || return 1
  run_phase "Node.js" phase_nodejs "required" || return 1
  run_phase "Caddy" phase_caddy "required" || return 1
  run_phase "Gotify" phase_gotify "optional"
  run_phase "CVEMonitoring" phase_cve "optional"
  run_phase "Application" phase_application "required" || return 1
  run_phase "Systemd" phase_systemd "required" || return 1
  run_phase "Firewall" phase_firewall "required" || return 1
  run_phase "HealthChecks" phase_health_checks "optional"

  # Save credentials
  save_credentials "/root/veracity-install-credentials.txt"

  # Calculate installation time
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))
  local minutes=$((duration / 60))
  local seconds=$((duration % 60))

  # Print summary
  print_summary

  success "Installation completed in ${minutes}m ${seconds}s!"
}

#######################################
# Handle resume mode
#######################################
handle_resume() {
  section "Resuming Installation"

  # Load configuration from state file
  if [ -f "/var/lib/veracity-installer/config" ]; then
    info "Loading saved configuration..."
    # shellcheck source=/dev/null
    source "/var/lib/veracity-installer/config"
  else
    fatal "No saved configuration found. Cannot resume installation."
  fi

  show_resume_info
  echo ""

  if ! confirm "Continue with installation?" "y"; then
    info "Installation cancelled"
    exit 0
  fi

  # Run installation (will skip completed phases)
  run_installation
}

#######################################
# Main installation flow
#######################################
main() {
  # Check for resume flag
  if [[ "${1:-}" == "--resume" ]]; then
    # Initialize logging first
    init_logging
    # Initialize error handling
    init_error_handling
    handle_resume
    exit 0
  fi

  # Check for rollback flag
  if [[ "${1:-}" == "--rollback" ]]; then
    init_logging
    init_error_handling
    execute_rollback
    exit 0
  fi

  # Initialize logging
  init_logging

  # Initialize error handling system
  init_error_handling

  # Print banner
  print_banner

  # Pause to let user read
  sleep 2

  # Collect configuration
  collect_configuration

  # Save configuration for resume
  mkdir -p /var/lib/veracity-installer
  cat > /var/lib/veracity-installer/config << EOF
# Veracity Installation Configuration
# Generated: $(date)

export OS_ID="${OS_ID}"
export OS_NAME="${OS_NAME}"
export OS_VERSION="${OS_VERSION}"
export DB_NAME="${DB_NAME}"
export DB_USER="${DB_USER}"
export DB_PASSWORD="${DB_PASSWORD}"
export DB_HOST="${DB_HOST}"
export SALT_API_USER="${SALT_API_USER}"
export SALT_API_PASSWORD="${SALT_API_PASSWORD}"
export SALT_API_URL="${SALT_API_URL}"
export SALT_API_EAUTH="${SALT_API_EAUTH}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE}"
export REDIS_URL="${REDIS_URL}"
export ADMIN_EMAIL="${ADMIN_EMAIL}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD}"
export RAILS_HOST="${RAILS_HOST}"
export RAILS_PROTOCOL="${RAILS_PROTOCOL}"
export RAILS_FORCE_SSL="${RAILS_FORCE_SSL}"
export RAILS_LOG_LEVEL="info"
export RAILS_MAX_THREADS="10"
export GOTIFY_ENABLED="${GOTIFY_ENABLED}"
export GOTIFY_PORT="${GOTIFY_PORT}"
export GOTIFY_ADMIN_USER="${GOTIFY_ADMIN_USER}"
export GOTIFY_ADMIN_PASSWORD="${GOTIFY_ADMIN_PASSWORD}"
export GOTIFY_URL="${GOTIFY_URL}"
export GOTIFY_HOST="${GOTIFY_HOST}"
export GOTIFY_APP_TOKEN="${GOTIFY_APP_TOKEN}"
export OAUTH_ENABLED="${OAUTH_ENABLED}"
export ZITADEL_ISSUER="${ZITADEL_ISSUER}"
export ZITADEL_CLIENT_ID="${ZITADEL_CLIENT_ID}"
export CVE_ENABLED="${CVE_ENABLED}"
export CVE_URL="${CVE_URL}"
export CVE_SCHEDULE="${CVE_SCHEDULE}"
export TZ="${TZ}"
export INSTALL_URL="${INSTALL_URL}"
export WEB_CONCURRENCY="2"
EOF
  chmod 600 /var/lib/veracity-installer/config

  # Show summary and confirm
  confirm_installation

  # Run installation
  if run_installation; then
    echo ""
    success "Veracity is now installed and running!"
    echo ""
    info "Access your dashboard at: ${INSTALL_URL}"
    info "Admin credentials saved to: /root/veracity-install-credentials.txt"
    echo ""
    info "Next steps:"
    echo "  1. Access ${INSTALL_URL} and log in"
    echo "  2. Enable 2FA for security"
    echo "  3. Install minions: curl -sSL ${INSTALL_URL}/install/minion.sh | sudo bash"
    echo "  4. Configure optional integrations via Settings"
    echo ""
    info "Documentation: https://github.com/Pwoodlock/veracity-"
    info "Support: https://github.com/Pwoodlock/veracity-/issues"
    echo ""
  else
    echo ""
    error "Installation failed. Please check the error messages above."
    echo ""
    info "You can try:"
    echo "  1. Fix the reported issues"
    echo "  2. Resume installation: sudo ./install.sh --resume"
    echo "  3. Rollback changes: sudo ./install.sh --rollback"
    echo ""
    exit 1
  fi
}

# Run main function
main "$@"
