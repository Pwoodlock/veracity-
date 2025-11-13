#!/bin/bash
#
# gotify.sh - Gotify push notification server installation
# Optional: Installs Gotify via Docker for push notifications
#

set -euo pipefail

# Source common functions
SERVICE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SERVICE_SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/validators.sh
source "${SERVICE_SCRIPT_DIR}/../lib/validators.sh"

# Default configuration
readonly GOTIFY_PORT="${GOTIFY_PORT:-8080}"
readonly GOTIFY_DATA_DIR="${GOTIFY_DATA_DIR:-/var/lib/gotify}"
readonly GOTIFY_ADMIN_USER="${GOTIFY_ADMIN_USER:-admin}"

#######################################
# Install Docker if needed
#######################################
install_docker() {
  if command_exists docker; then
    info "Docker is already installed"
    return 0
  fi

  step "Installing Docker..."

  # Detect OS if not already set (handles resume scenario)
  if [ -z "${OS_ID:-}" ]; then
    info "OS not detected, detecting now..."
    if [ -f /etc/os-release ]; then
      # shellcheck source=/dev/null
      . /etc/os-release
      export OS_ID="$ID"
      export OS_NAME="$NAME"
      export OS_VERSION="${VERSION_ID:-unknown}"
    else
      fatal "Cannot detect operating system. /etc/os-release not found."
    fi
  fi

  case "${OS_ID}" in
    ubuntu|debian)
      # Install Docker on Debian/Ubuntu
      install_packages ca-certificates curl gnupg

      # Add Docker GPG key
      install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      chmod a+r /etc/apt/keyrings/docker.gpg

      # Add Docker repository
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS_ID} \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

      execute apt-get update -qq
      install_packages docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;

    rocky|almalinux|rhel)
      # Install Docker on RHEL/Rocky
      execute dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
      install_packages docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;

    *)
      fatal "Unsupported OS for Docker installation: ${OS_ID}"
      ;;
  esac

  # Start and enable Docker
  execute systemctl start docker
  execute systemctl enable docker

  if wait_for_service docker; then
    success "Docker installed and started"
  else
    fatal "Failed to start Docker"
  fi

  # Wait for Docker to be fully ready
  info "Waiting for Docker to be fully ready..."
  local max_attempts=10
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if docker info >/dev/null 2>&1; then
      success "Docker is ready"
      break
    fi
    attempt=$((attempt + 1))
    sleep 2
  done

  if [ $attempt -eq $max_attempts ]; then
    fatal "Docker failed to become ready after ${max_attempts} attempts"
  fi
}

#######################################
# Setup Gotify data directory
#######################################
setup_gotify_directory() {
  step "Creating Gotify data directory..."

  mkdir -p "${GOTIFY_DATA_DIR}"
  chmod 755 "${GOTIFY_DATA_DIR}"

  success "Gotify data directory created: ${GOTIFY_DATA_DIR}"
}

#######################################
# Install Gotify via Docker
#######################################
install_gotify_docker() {
  step "Installing Gotify via Docker..."

  # Pull Gotify image
  spinner "Pulling Gotify Docker image" execute docker pull gotify/server:latest

  # Stop and remove existing container if it exists
  if docker ps -a --format '{{.Names}}' | grep -q '^gotify$'; then
    warning "Existing Gotify container found, removing..."
    execute docker stop gotify || true
    execute docker rm gotify || true
  fi

  # Run Gotify container
  execute docker run -d \
    --name gotify \
    --restart unless-stopped \
    -p "${GOTIFY_PORT}:80" \
    -v "${GOTIFY_DATA_DIR}:/app/data" \
    -e "GOTIFY_DEFAULTUSER_NAME=${GOTIFY_ADMIN_USER}" \
    -e "GOTIFY_DEFAULTUSER_PASS=${GOTIFY_ADMIN_PASSWORD}" \
    gotify/server:latest

  # Wait for Gotify to start
  sleep 5

  if docker ps | grep -q gotify; then
    success "Gotify container started successfully"
  else
    fatal "Failed to start Gotify container"
  fi
}

#######################################
# Test Gotify installation
#######################################
test_gotify() {
  step "Testing Gotify installation..."

  local max_attempts=30
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    if curl -sSf "http://localhost:${GOTIFY_PORT}/health" -o /dev/null 2>&1; then
      success "Gotify is accessible at http://localhost:${GOTIFY_PORT}"
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  error "Gotify health check failed after ${max_attempts} attempts"
  return 1
}

#######################################
# Create Gotify application and get token
#######################################
create_gotify_app() {
  step "Creating Gotify application..."

  sleep 3  # Give Gotify time to initialize

  # Create application via API
  local response
  response=$(curl -sSf -X POST "http://localhost:${GOTIFY_PORT}/application" \
    -u "${GOTIFY_ADMIN_USER}:${GOTIFY_ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Veracity",
      "description": "Veracity Server Manager Notifications"
    }' 2>/dev/null || echo "")

  if [ -n "$response" ]; then
    # Extract app token from response
    GOTIFY_APP_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$GOTIFY_APP_TOKEN" ]; then
      success "Gotify application created"
      info "App Token: ${GOTIFY_APP_TOKEN}"
      return 0
    fi
  fi

  warning "Could not automatically create Gotify application"
  warning "Please create an application manually and configure the token in Veracity"
  return 1
}

#######################################
# Display Gotify information
#######################################
display_gotify_info() {
  section "Gotify Configuration"

  info "Gotify URL: http://localhost:${GOTIFY_PORT}"
  info "Admin Username: ${GOTIFY_ADMIN_USER}"
  info "Admin Password: ${GOTIFY_ADMIN_PASSWORD}"
  info "Data Directory: ${GOTIFY_DATA_DIR}"

  if [ -n "${GOTIFY_APP_TOKEN:-}" ]; then
    info "App Token: ${GOTIFY_APP_TOKEN}"
  fi

  echo ""
  if [ -n "${GOTIFY_HOST:-}" ]; then
    info "Access Gotify at: ${RAILS_PROTOCOL}://${GOTIFY_HOST}"
  else
    info "Access Gotify at: http://${RAILS_HOST}:${GOTIFY_PORT}"
    info "Or configure a subdomain (e.g., gotify.${RAILS_HOST})"
  fi

  echo ""
  warning "IMPORTANT: Secure Gotify behind a reverse proxy for production use"
  warning "Consider adding to Caddyfile for HTTPS access"
}

#######################################
# Configure firewall for Gotify
#######################################
configure_gotify_firewall() {
  if command_exists ufw; then
    # Skip firewall configuration - Gotify is accessed via reverse proxy (Caddy)
    info "Gotify will be accessed via reverse proxy (Caddy), skipping direct port access"
  fi
}

#######################################
# Setup Gotify for Veracity
# Main function that orchestrates Gotify setup
# Globals:
#   GOTIFY_ADMIN_PASSWORD, RAILS_HOST
#######################################
setup_gotify() {
  section "Installing Gotify Push Notification Server"

  # Validate required variables
  if [ -z "${GOTIFY_ADMIN_PASSWORD:-}" ]; then
    fatal "GOTIFY_ADMIN_PASSWORD environment variable is required"
  fi

  # Ask for installation method
  info "Gotify can be installed via Docker (recommended) or binary"

  if ! command_exists docker; then
    info "Docker is not installed. Installing Docker for Gotify..."
    install_docker
  fi

  setup_gotify_directory
  install_gotify_docker
  test_gotify
  create_gotify_app || true
  display_gotify_info
  configure_gotify_firewall

  success "Gotify setup complete!"

  # Export variables for use in .env
  export GOTIFY_URL="http://localhost:${GOTIFY_PORT}"
  export GOTIFY_ENABLED="true"
}

# If script is executed directly, run setup
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_gotify
fi
