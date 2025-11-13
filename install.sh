#!/bin/bash
#
# Veracity - One-Click Interactive Installer
# Interactive installation script for Veracity Server Manager
#
# Usage: curl -sSL https://raw.githubusercontent.com/Pwoodlock/veracity/main/install.sh | sudo bash
#        or: sudo ./install.sh
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
# shellcheck source=scripts/install/lib/common.sh
source "${SCRIPT_DIR}/scripts/install/lib/common.sh"
# shellcheck source=scripts/install/lib/validators.sh
source "${SCRIPT_DIR}/scripts/install/lib/validators.sh"

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
# Run installation steps
#######################################
run_installation() {
  local start_time
  start_time=$(date +%s)

  # Prerequisites
  check_prerequisites

  # Export configuration
  export OS_ID OS_NAME OS_VERSION
  export DB_NAME DB_USER DB_PASSWORD DB_HOST
  export SALT_API_USER SALT_API_PASSWORD SALT_API_URL SALT_API_EAUTH
  export SECRET_KEY_BASE REDIS_URL
  export ADMIN_EMAIL ADMIN_PASSWORD
  export RAILS_HOST RAILS_PROTOCOL RAILS_FORCE_SSL RAILS_LOG_LEVEL="info" RAILS_MAX_THREADS="10"
  export GOTIFY_ENABLED GOTIFY_PORT GOTIFY_ADMIN_USER GOTIFY_ADMIN_PASSWORD GOTIFY_URL GOTIFY_APP_TOKEN
  export OAUTH_ENABLED ZITADEL_ISSUER ZITADEL_CLIENT_ID
  export CVE_ENABLED CVE_URL CVE_SCHEDULE
  export TZ INSTALL_URL WEB_CONCURRENCY="2"

  # Update system
  update_system_packages

  # Install services (parallel where possible)
  progress_bar 1 10 "Installing PostgreSQL..."
  source "${SCRIPT_DIR}/scripts/install/services/postgresql.sh"
  setup_postgresql

  progress_bar 2 10 "Installing Redis..."
  source "${SCRIPT_DIR}/scripts/install/services/redis.sh"
  setup_redis

  progress_bar 3 10 "Installing SaltStack..."
  source "${SCRIPT_DIR}/scripts/install/services/salt.sh"
  setup_salt

  progress_bar 4 10 "Installing Ruby 3.3.5..."
  source "${SCRIPT_DIR}/scripts/install/services/ruby.sh"
  setup_ruby

  progress_bar 5 10 "Installing Node.js..."
  source "${SCRIPT_DIR}/scripts/install/services/nodejs.sh"
  setup_nodejs

  progress_bar 6 10 "Installing Caddy..."
  source "${SCRIPT_DIR}/scripts/install/services/caddy.sh"
  setup_caddy

  progress_bar 7 10 "Installing Gotify..."
  source "${SCRIPT_DIR}/scripts/install/services/gotify.sh"
  setup_gotify || warning "Gotify installation failed, continuing..."

  progress_bar 7.5 10 "Installing CVE monitoring..."
  source "${SCRIPT_DIR}/scripts/install/services/cve_monitoring.sh"
  setup_cve_monitoring || warning "CVE monitoring installation failed, continuing..."

  progress_bar 8 10 "Setting up application..."
  source "${SCRIPT_DIR}/scripts/install/app-setup.sh"
  setup_application

  progress_bar 9 10 "Configuring systemd services..."
  source "${SCRIPT_DIR}/scripts/install/systemd-setup.sh"
  setup_systemd

  progress_bar 10 10 "Configuring firewall..."
  source "${SCRIPT_DIR}/scripts/install/firewall.sh"
  setup_firewall

  # Health checks
  echo ""
  source "${SCRIPT_DIR}/scripts/install/health-check.sh"
  run_health_checks || warning "Some health checks failed"

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
# Main installation flow
#######################################
main() {
  # Initialize logging
  init_logging

  # Print banner
  print_banner

  # Pause to let user read
  sleep 2

  # Collect configuration
  collect_configuration

  # Show summary and confirm
  confirm_installation

  # Run installation
  run_installation

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
}

# Run main function
main "$@"
