#!/bin/bash
#
# ruby.sh - Ruby installation via Fullstaq Ruby (precompiled binaries)
# Installs Fullstaq Ruby 3.3.5 with jemalloc for production performance
#

set -euo pipefail

# Source common functions
SERVICE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SERVICE_SCRIPT_DIR}/../lib/common.sh"
# shellcheck source=../lib/validators.sh
source "${SERVICE_SCRIPT_DIR}/../lib/validators.sh"

# Ruby version to install
readonly RUBY_VERSION="3.3.5"
readonly RUBY_VARIANT="jemalloc"  # Use jemalloc variant for better memory performance
readonly DEPLOY_USER="deploy"
readonly DEPLOY_HOME="/home/${DEPLOY_USER}"

#######################################
# Add Fullstaq Ruby APT repository (Debian/Ubuntu)
#######################################
add_fullstaq_repo_debian() {
  step "Adding Fullstaq Ruby repository..."

  # Install dependencies
  install_packages ca-certificates curl gnupg apt-transport-https

  # Add Fullstaq Ruby GPG key with retry logic
  local gpg_url="https://raw.githubusercontent.com/fullstaq-labs/fullstaq-ruby-server-edition/main/fullstaq-ruby.asc"
  local gpg_tmp="/tmp/fullstaq-ruby.asc"
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    info "Downloading Fullstaq Ruby GPG key (attempt $attempt/$max_attempts)..."

    if curl -fsSL "${gpg_url}" -o "${gpg_tmp}"; then
      # Verify we got valid GPG data using gpg itself
      if gpg --list-packets "${gpg_tmp}" &>/dev/null; then
        execute gpg --dearmor -o /usr/share/keyrings/fullstaq-ruby.gpg < "${gpg_tmp}"
        rm -f "${gpg_tmp}"
        success "GPG key downloaded and installed"
        break
      else
        warning "Downloaded file is not valid GPG data"
      fi
    else
      warning "Failed to download GPG key"
    fi

    if [ $attempt -eq $max_attempts ]; then
      rm -f "${gpg_tmp}"
      fatal "Failed to download Fullstaq Ruby GPG key after $max_attempts attempts"
    fi

    attempt=$((attempt + 1))
    sleep 5
  done

  # Add repository
  # Fullstaq Ruby uses "ubuntu-VERSION" format instead of codenames
  local ubuntu_version
  if [ -f /etc/os-release ]; then
    ubuntu_version=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "deb [signed-by=/usr/share/keyrings/fullstaq-ruby.gpg] https://apt.fullstaqruby.org ubuntu-${ubuntu_version} main" | tee /etc/apt/sources.list.d/fullstaq-ruby.list > /dev/null
  else
    # Fallback to codename if VERSION_ID not found
    echo "deb [signed-by=/usr/share/keyrings/fullstaq-ruby.gpg] https://apt.fullstaqruby.org $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/fullstaq-ruby.list > /dev/null
  fi

  # Update package lists
  execute apt-get update

  success "Fullstaq Ruby repository added"
}

#######################################
# Add Fullstaq Ruby YUM repository (RHEL/Rocky/Alma)
#######################################
add_fullstaq_repo_rhel() {
  step "Adding Fullstaq Ruby repository..."

  # Add Fullstaq Ruby repository
  cat > /etc/yum.repos.d/fullstaq-ruby.repo << 'EOF'
[fullstaq-ruby]
name=Fullstaq Ruby
baseurl=https://yum.fullstaqruby.org/centos-$releasever/$basearch
gpgcheck=1
gpgkey=https://raw.githubusercontent.com/fullstaq-labs/fullstaq-ruby-server-edition/main/fullstaq-ruby.asc
enabled=1
EOF

  # Update package lists
  execute dnf makecache

  success "Fullstaq Ruby repository added"
}

#######################################
# Create deploy user
#######################################
create_deploy_user() {
  step "Creating deploy user..."

  if user_exists "${DEPLOY_USER}"; then
    info "User ${DEPLOY_USER} already exists"
    return 0
  fi

  # Create deploy user with home directory
  execute useradd -m -s /bin/bash -c "Veracity Deploy User" "${DEPLOY_USER}"

  # Add deploy user to necessary groups
  if getent group www-data &>/dev/null; then
    execute usermod -aG www-data "${DEPLOY_USER}"
  fi

  success "Deploy user created: ${DEPLOY_USER}"
}

#######################################
# Install Fullstaq Ruby (Debian/Ubuntu)
#######################################
install_fullstaq_ruby_debian() {
  step "Installing Fullstaq Ruby ${RUBY_VERSION}-${RUBY_VARIANT}..."

  # Install Fullstaq Ruby package (takes seconds, not minutes!)
  local package_name="fullstaq-ruby-${RUBY_VERSION}-${RUBY_VARIANT}"

  spinner "Installing ${package_name}" install_packages "${package_name}"

  # Install bundler and common-${RUBY_VARIANT} for shared libraries
  install_packages "fullstaq-ruby-common-${RUBY_VARIANT}"

  success "Fullstaq Ruby ${RUBY_VERSION} installed in seconds!"
}

#######################################
# Install Fullstaq Ruby (RHEL/Rocky/Alma)
#######################################
install_fullstaq_ruby_rhel() {
  step "Installing Fullstaq Ruby ${RUBY_VERSION}-${RUBY_VARIANT}..."

  # Install Fullstaq Ruby package
  local package_name="fullstaq-ruby-${RUBY_VERSION}-${RUBY_VARIANT}"

  spinner "Installing ${package_name}" install_packages "${package_name}"

  # Install common package
  install_packages "fullstaq-ruby-common-${RUBY_VARIANT}"

  success "Fullstaq Ruby ${RUBY_VERSION} installed in seconds!"
}

#######################################
# Configure Fullstaq Ruby for deploy user
#######################################
configure_fullstaq_ruby() {
  step "Configuring Fullstaq Ruby for ${DEPLOY_USER}..."

  # Fullstaq Ruby installs to /usr/local/fullstaq-ruby/versions/ruby-X.X.X-VARIANT
  local ruby_dir="/usr/local/fullstaq-ruby/versions/ruby-${RUBY_VERSION}-${RUBY_VARIANT}"

  # Add to deploy user's PATH
  if ! grep -q 'fullstaq-ruby' "${DEPLOY_HOME}/.bashrc" 2>/dev/null; then
    cat >> "${DEPLOY_HOME}/.bashrc" << EOF

# Fullstaq Ruby
export PATH="${ruby_dir}/bin:\$PATH"
export GEM_HOME="${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}"
export GEM_PATH="${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}:${ruby_dir}/lib/ruby/gems/${RUBY_VERSION%.*}.0"
EOF
    execute chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.bashrc"
    success "Fullstaq Ruby added to PATH"
  fi

  # Ensure .bash_profile sources .bashrc
  if [ ! -f "${DEPLOY_HOME}/.bash_profile" ]; then
    cat > "${DEPLOY_HOME}/.bash_profile" << 'EOF'
# Source .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
EOF
    execute chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.bash_profile"
  fi

  # Create gem directory
  execute mkdir -p "${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}"
  execute chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.gem"

  # Create symlinks for system-wide access
  if [ ! -L /usr/local/bin/ruby ]; then
    execute ln -sf "${ruby_dir}/bin/ruby" /usr/local/bin/ruby
  fi
  if [ ! -L /usr/local/bin/gem ]; then
    execute ln -sf "${ruby_dir}/bin/gem" /usr/local/bin/gem
  fi

  success "Fullstaq Ruby configured"
}

#######################################
# Install bundler
#######################################
install_bundler() {
  step "Installing bundler..."

  local ruby_dir="/usr/local/fullstaq-ruby/versions/ruby-${RUBY_VERSION}-${RUBY_VARIANT}"
  local ruby_cmd="export PATH=\"${ruby_dir}/bin:\$PATH\" && export GEM_HOME=\"${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}\" && "

  execute sudo -u "${DEPLOY_USER}" bash -c "${ruby_cmd} gem install bundler --no-document"

  # Create symlink for bundle
  if [ ! -L /usr/local/bin/bundle ]; then
    execute ln -sf "${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}/bin/bundle" /usr/local/bin/bundle || \
    execute ln -sf "${ruby_dir}/bin/bundle" /usr/local/bin/bundle
  fi

  success "Bundler installed"
}

#######################################
# Verify Ruby installation
#######################################
verify_ruby() {
  step "Verifying Fullstaq Ruby installation..."

  local ruby_dir="/usr/local/fullstaq-ruby/versions/ruby-${RUBY_VERSION}-${RUBY_VARIANT}"
  local ruby_cmd="export PATH=\"${ruby_dir}/bin:\$PATH\" && export GEM_HOME=\"${DEPLOY_HOME}/.gem/ruby/${RUBY_VERSION}\" && "

  local ruby_version
  ruby_version=$(sudo -u "${DEPLOY_USER}" bash -c "${ruby_cmd} ruby -v")
  info "Ruby version: ${ruby_version}"

  local gem_version
  gem_version=$(sudo -u "${DEPLOY_USER}" bash -c "${ruby_cmd} gem -v")
  info "RubyGems version: ${gem_version}"

  local bundler_version
  bundler_version=$(sudo -u "${DEPLOY_USER}" bash -c "${ruby_cmd} bundler -v")
  info "Bundler version: ${bundler_version}"

  # Verify correct Ruby version
  if sudo -u "${DEPLOY_USER}" bash -c "${ruby_cmd} ruby -v" | grep -q "${RUBY_VERSION}"; then
    success "Fullstaq Ruby ${RUBY_VERSION}-${RUBY_VARIANT} verified successfully"
  else
    fatal "Ruby version mismatch"
  fi

  # Verify jemalloc is enabled
  if ldd "${ruby_dir}/bin/ruby" | grep -q jemalloc; then
    success "jemalloc memory allocator enabled"
  else
    warning "jemalloc not detected (expected for ${RUBY_VARIANT} variant)"
  fi
}

#######################################
# Configure gem installation settings
#######################################
configure_gem_settings() {
  step "Configuring gem settings..."

  # Create .gemrc to skip documentation
  cat > "${DEPLOY_HOME}/.gemrc" << EOF
---
gem: --no-document
install: --no-document
update: --no-document
EOF

  execute chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.gemrc"

  success "Gem settings configured"
}

#######################################
# Setup Ruby for Veracity
# Main function that orchestrates Ruby setup
#######################################
setup_ruby() {
  section "Installing Fullstaq Ruby ${RUBY_VERSION}-${RUBY_VARIANT}"

  # Detect OS if not already set
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

  # Create deploy user
  create_deploy_user

  # Add Fullstaq repository and install Ruby (OS-specific)
  case "${OS_ID}" in
    ubuntu|debian)
      add_fullstaq_repo_debian
      install_fullstaq_ruby_debian
      ;;
    rocky|almalinux|rhel)
      add_fullstaq_repo_rhel
      install_fullstaq_ruby_rhel
      ;;
    *)
      fatal "Unsupported OS for Fullstaq Ruby: ${OS_ID}"
      ;;
  esac

  # Configure Ruby for deploy user
  configure_fullstaq_ruby
  configure_gem_settings
  install_bundler
  verify_ruby

  success "Fullstaq Ruby setup complete!"
  info "Deploy user: ${DEPLOY_USER}"
  info "Ruby version: ${RUBY_VERSION}-${RUBY_VARIANT}"
  info "Ruby location: /usr/local/fullstaq-ruby/versions/ruby-${RUBY_VERSION}-${RUBY_VARIANT}"
  info "Installation time: ~30 seconds (vs 10-20 minutes with source compilation)"
}

# If script is executed directly, run setup
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_ruby
fi
