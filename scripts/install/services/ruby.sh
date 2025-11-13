#!/bin/bash
#
# ruby.sh - Ruby installation via rbenv
# Installs rbenv, ruby-build, and Ruby 3.3.5 for deploy user
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
readonly DEPLOY_USER="deploy"
readonly DEPLOY_HOME="/home/${DEPLOY_USER}"

#######################################
# Install Ruby dependencies
# Globals:
#   OS_ID
#######################################
install_ruby_dependencies() {
  step "Installing Ruby build dependencies..."

  case "${OS_ID}" in
    ubuntu|debian)
      spinner "Installing dependencies" install_packages \
        build-essential libssl-dev libreadline-dev zlib1g-dev \
        libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev \
        libffi-dev autoconf bison patch rustc libjemalloc-dev
      ;;
    rocky|almalinux|rhel)
      spinner "Installing dependencies" install_packages \
        gcc gcc-c++ make openssl-devel readline-devel zlib-devel \
        libyaml-devel libxml2-devel libxslt-devel libcurl-devel \
        libffi-devel autoconf bison patch rust cargo jemalloc-devel
      ;;
    *)
      fatal "Unsupported OS for Ruby dependencies: ${OS_ID}"
      ;;
  esac

  success "Ruby dependencies installed"
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
# Install rbenv for deploy user
#######################################
install_rbenv() {
  step "Installing rbenv for ${DEPLOY_USER}..."

  # Clone rbenv
  if [ ! -d "${DEPLOY_HOME}/.rbenv" ]; then
    execute sudo -u "${DEPLOY_USER}" git clone https://github.com/rbenv/rbenv.git "${DEPLOY_HOME}/.rbenv"
    success "rbenv cloned"
  else
    info "rbenv already installed"
  fi

  # Compile bash extension for speed
  execute sudo -u "${DEPLOY_USER}" bash -c "cd ${DEPLOY_HOME}/.rbenv && src/configure && make -C src" || true

  # Clone ruby-build plugin
  if [ ! -d "${DEPLOY_HOME}/.rbenv/plugins/ruby-build" ]; then
    execute sudo -u "${DEPLOY_USER}" git clone https://github.com/rbenv/ruby-build.git \
      "${DEPLOY_HOME}/.rbenv/plugins/ruby-build"
    success "ruby-build plugin installed"
  else
    info "ruby-build already installed"
  fi

  # Add rbenv to PATH in .bashrc
  if ! grep -q 'rbenv init' "${DEPLOY_HOME}/.bashrc"; then
    cat >> "${DEPLOY_HOME}/.bashrc" << 'EOF'

# rbenv initialization
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
EOF
    execute chown "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_HOME}/.bashrc"
    success "rbenv added to .bashrc"
  fi

  success "rbenv installed successfully"
}

#######################################
# Install Ruby via rbenv
#######################################
install_ruby() {
  step "Installing Ruby ${RUBY_VERSION}..."

  info "This may take 10-15 minutes..."

  # Check if Ruby version is already installed
  if sudo -u "${DEPLOY_USER}" bash -lc "rbenv versions | grep -q ${RUBY_VERSION}"; then
    info "Ruby ${RUBY_VERSION} already installed"
  else
    # Install Ruby with jemalloc for better memory performance
    if ! sudo -u "${DEPLOY_USER}" bash -lc "RUBY_CONFIGURE_OPTS='--with-jemalloc' rbenv install ${RUBY_VERSION}" >> "${LOG_FILE}" 2>&1; then
      warning "Failed to install with jemalloc, trying without..."
      execute sudo -u "${DEPLOY_USER}" bash -lc "rbenv install ${RUBY_VERSION}"
    fi
    success "Ruby ${RUBY_VERSION} installed"
  fi

  # Set global Ruby version
  execute sudo -u "${DEPLOY_USER}" bash -lc "rbenv global ${RUBY_VERSION}"

  # Rehash rbenv
  execute sudo -u "${DEPLOY_USER}" bash -lc "rbenv rehash"

  success "Ruby ${RUBY_VERSION} set as global version"
}

#######################################
# Install bundler
#######################################
install_bundler() {
  step "Installing bundler..."

  execute sudo -u "${DEPLOY_USER}" bash -lc "gem install bundler --no-document"
  execute sudo -u "${DEPLOY_USER}" bash -lc "rbenv rehash"

  success "Bundler installed"
}

#######################################
# Verify Ruby installation
#######################################
verify_ruby() {
  step "Verifying Ruby installation..."

  local ruby_version
  ruby_version=$(sudo -u "${DEPLOY_USER}" bash -lc "ruby -v")
  info "Ruby version: ${ruby_version}"

  local gem_version
  gem_version=$(sudo -u "${DEPLOY_USER}" bash -lc "gem -v")
  info "RubyGems version: ${gem_version}"

  local bundler_version
  bundler_version=$(sudo -u "${DEPLOY_USER}" bash -lc "bundler -v")
  info "Bundler version: ${bundler_version}"

  # Verify correct Ruby version
  if sudo -u "${DEPLOY_USER}" bash -lc "ruby -v" | grep -q "${RUBY_VERSION}"; then
    success "Ruby ${RUBY_VERSION} verified successfully"
  else
    fatal "Ruby version mismatch"
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
  section "Installing Ruby ${RUBY_VERSION}"

  install_ruby_dependencies
  create_deploy_user
  install_rbenv
  install_ruby
  configure_gem_settings
  install_bundler
  verify_ruby

  # Create symbolic links for easier access
  if [ ! -L /usr/local/bin/bundle ]; then
    execute ln -sf "${DEPLOY_HOME}/.rbenv/shims/bundle" /usr/local/bin/bundle || true
  fi
  if [ ! -L /usr/local/bin/ruby ]; then
    execute ln -sf "${DEPLOY_HOME}/.rbenv/shims/ruby" /usr/local/bin/ruby || true
  fi

  success "Ruby setup complete!"
  info "Deploy user: ${DEPLOY_USER}"
  info "Ruby version: ${RUBY_VERSION}"
  info "rbenv location: ${DEPLOY_HOME}/.rbenv"
}

# If script is executed directly, run setup
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  setup_ruby
fi
