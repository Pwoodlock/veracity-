#!/bin/bash
#
# cve_monitoring.sh - CVE vulnerability scanning setup
# Installs Python virtual environment with PyVulnerabilityLookup
#

set -euo pipefail

# Source common functions
SERVICE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SERVICE_SCRIPT_DIR}/../lib/common.sh"

# Configuration
readonly APP_DIR="/opt/veracity/app"
readonly CVE_VENV_DIR="${APP_DIR}/cve_venv"
readonly CVE_WRAPPER="${APP_DIR}/bin/cve_python"
readonly DEPLOY_USER="deploy"

#######################################
# Install Python 3 and venv
#######################################
install_python() {
  step "Installing Python 3 and virtual environment support..."

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
      install_packages python3 python3-venv python3-pip python3-full
      ;;

    rocky|almalinux|rhel)
      install_packages python3 python3-pip python3-virtualenv
      ;;

    *)
      fatal "Unsupported OS for Python installation: ${OS_ID}"
      ;;
  esac

  # Verify Python installation
  if ! command_exists python3; then
    fatal "Python 3 installation failed"
  fi

  local python_version
  python_version=$(python3 --version 2>&1 | awk '{print $2}')

  # Verify Python version >= 3.8 (required for PyVulnerabilityLookup)
  local major=$(echo "$python_version" | cut -d. -f1)
  local minor=$(echo "$python_version" | cut -d. -f2)

  if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 8 ]); then
    fatal "Python 3.8+ required for PyVulnerabilityLookup, found: ${python_version}"
  fi

  success "Python ${python_version} installed (>= 3.8 required)"
}

#######################################
# Create Python virtual environment
#######################################
create_virtualenv() {
  step "Creating Python virtual environment at ${CVE_VENV_DIR}..."

  # Remove existing venv if present
  if [ -d "${CVE_VENV_DIR}" ]; then
    warning "Existing virtual environment found, recreating..."
    rm -rf "${CVE_VENV_DIR}"
  fi

  # Create venv
  execute python3 -m venv "${CVE_VENV_DIR}"

  # Set ownership
  execute chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${CVE_VENV_DIR}"

  success "Virtual environment created"
}

#######################################
# Install PyVulnerabilityLookup
#######################################
install_pyvulnerabilitylookup() {
  step "Installing PyVulnerabilityLookup and dependencies..."

  # Upgrade pip first
  info "Upgrading pip..."
  execute "${CVE_VENV_DIR}/bin/pip" install --upgrade pip

  # Install required packages
  info "Installing pyvulnerabilitylookup and requests..."
  if ! "${CVE_VENV_DIR}/bin/pip" install "pyvulnerabilitylookup>=2.0.0" "requests>=2.28.0" >> "${LOG_FILE}" 2>&1; then
    fatal "Failed to install PyVulnerabilityLookup. Check ${LOG_FILE} for details"
  fi

  success "PyVulnerabilityLookup installed successfully"
}

#######################################
# Test PyVulnerabilityLookup installation
#######################################
test_pyvulnerabilitylookup() {
  step "Testing PyVulnerabilityLookup installation..."

  # Test import and version
  if "${CVE_VENV_DIR}/bin/python" -c "import pyvulnerabilitylookup; print('PyVulnerabilityLookup version:', pyvulnerabilitylookup.__version__)" >> "${LOG_FILE}" 2>&1; then
    local version
    version=$("${CVE_VENV_DIR}/bin/python" -c "import pyvulnerabilitylookup; print(pyvulnerabilitylookup.__version__)" 2>/dev/null)
    success "PyVulnerabilityLookup ${version} is working"
  else
    error "PyVulnerabilityLookup test failed"
    return 1
  fi
}

#######################################
# Create Python wrapper script
#######################################
create_wrapper_script() {
  step "Creating Python wrapper script..."

  # Create bin directory if it doesn't exist
  mkdir -p "${APP_DIR}/bin"

  # Create wrapper script
  cat > "${CVE_WRAPPER}" << 'EOF'
#!/bin/bash
# Python wrapper for CVE monitoring
# Uses the virtual environment for PyVulnerabilityLookup
/opt/veracity/app/cve_venv/bin/python "$@"
EOF

  # Make executable
  execute chmod +x "${CVE_WRAPPER}"
  execute chown "${DEPLOY_USER}:${DEPLOY_USER}" "${CVE_WRAPPER}"

  success "Wrapper script created at ${CVE_WRAPPER}"
}

#######################################
# Display CVE monitoring information
#######################################
display_cve_info() {
  section "CVE Monitoring Configuration"

  info "Virtual Environment: ${CVE_VENV_DIR}"
  info "Python Wrapper: ${CVE_WRAPPER}"
  info "Vulnerability API: ${CVE_URL:-https://vulnerability.circl.lu}"
  info "Scan Schedule: ${CVE_SCHEDULE:-0 2 * * *} (daily at 2 AM)"

  echo ""
  info "CVE monitoring features:"
  echo "  • Automatic vulnerability scanning for all servers"
  echo "  • Proxmox VE CVE tracking"
  echo "  • OS-specific vulnerability detection"
  echo "  • Critical CVE email alerts"
  echo "  • Configurable scan schedules"

  echo ""
  info "Configure additional watchlists via the web UI after installation"
}

#######################################
# Setup CVE monitoring for Veracity
# Main function that orchestrates CVE setup
#######################################
setup_cve_monitoring() {
  section "Installing CVE Vulnerability Monitoring"

  install_python
  create_virtualenv
  install_pyvulnerabilitylookup
  test_pyvulnerabilitylookup
  create_wrapper_script
  display_cve_info

  success "CVE monitoring setup complete!"

  # Export variables for use in .env
  export VULNERABILITY_LOOKUP_ENABLED="true"
  export VULNERABILITY_LOOKUP_URL="${CVE_URL:-https://vulnerability.circl.lu}"
  export VULNERABILITY_LOOKUP_SCAN_SCHEDULE="${CVE_SCHEDULE:-0 2 * * *}"
  export VULNERABILITY_LOOKUP_PYTHON_PATH="${CVE_WRAPPER}"
  export VULNERABILITY_LOOKUP_TIMEOUT="60"
}

# If script is executed directly, run setup
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_cve_monitoring
fi
