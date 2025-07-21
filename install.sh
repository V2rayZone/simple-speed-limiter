#!/bin/bash

# Simple Speed Limiter - One-Line Installer
# Usage: bash <(curl -Ls https://raw.githubusercontent.com/V2rayZone/simple-speed-limiter/main/install.sh)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/simple-speed-limiter"
BIN_LINK="/usr/local/bin/simple-speed-limiter"
GITHUB_REPO="https://raw.githubusercontent.com/V2rayZone/simple-speed-limiter/main"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This installer must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check if we're on a supported system
    if ! command -v tc &> /dev/null; then
        print_error "Traffic control (tc) not found. Please install iproute2:"
        echo "  Ubuntu/Debian: apt install iproute2"
        echo "  CentOS/RHEL: yum install iproute"
        exit 1
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl not found. Please install curl first."
        exit 1
    fi
    
    print_success "System requirements met"
}

# Function to create installation directory
create_install_dir() {
    print_info "Creating installation directory: $INSTALL_DIR"
    
    # Remove existing installation if present
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Existing installation found. Removing..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Create directory
    mkdir -p "$INSTALL_DIR"
    print_success "Installation directory created"
}

# Function to download files from GitHub
download_files() {
    print_info "Downloading files from GitHub repository..."
    
    # Download main script
    print_info "Downloading simple_speed_limiter.sh..."
    if ! curl -fsSL "$GITHUB_REPO/simple_speed_limiter.sh" -o "$INSTALL_DIR/simple_speed_limiter.sh"; then
        print_error "Failed to download simple_speed_limiter.sh"
        exit 1
    fi
    
    # Download configuration file
    print_info "Downloading config.env..."
    if ! curl -fsSL "$GITHUB_REPO/config.env" -o "$INSTALL_DIR/config.env"; then
        print_error "Failed to download config.env"
        exit 1
    fi
    
    # Download README (optional)
    print_info "Downloading README.md..."
    curl -fsSL "$GITHUB_REPO/README.md" -o "$INSTALL_DIR/README.md" 2>/dev/null || print_warning "README.md download failed (non-critical)"
    
    print_success "Files downloaded successfully"
}

# Function to set permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    # Make script executable
    chmod +x "$INSTALL_DIR/simple_speed_limiter.sh"
    
    # Set appropriate permissions for config file
    chmod 644 "$INSTALL_DIR/config.env"
    
    # Set ownership to root
    chown -R root:root "$INSTALL_DIR"
    
    print_success "Permissions set correctly"
}

# Function to create symlink
create_symlink() {
    print_info "Creating system-wide command symlink..."
    
    # Remove existing symlink if present
    if [[ -L "$BIN_LINK" ]]; then
        rm "$BIN_LINK"
    fi
    
    # Create symlink
    ln -s "$INSTALL_DIR/simple_speed_limiter.sh" "$BIN_LINK"
    
    print_success "Symlink created: $BIN_LINK"
}

# Function to detect network interface
detect_interface() {
    print_info "Detecting network interface..."
    
    # Get the default route interface
    DEFAULT_INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    
    if [[ -n "$DEFAULT_INTERFACE" ]]; then
        print_info "Detected network interface: $DEFAULT_INTERFACE"
        
        # Update config file with detected interface
        sed -i "s/INTERFACE=\"eth0\"/INTERFACE=\"$DEFAULT_INTERFACE\"/g" "$INSTALL_DIR/config.env"
        print_success "Configuration updated with detected interface"
    else
        print_warning "Could not detect network interface. Please check config.env manually."
    fi
}

# Function to install optional dependencies
install_optional_deps() {
    print_info "Installing optional dependencies..."
    
    # Try to install speedtest-cli for speed testing
    if command -v apt &> /dev/null; then
        print_info "Installing speedtest-cli via apt..."
        apt update -qq && apt install -y speedtest-cli 2>/dev/null || print_warning "speedtest-cli installation failed (non-critical)"
    elif command -v yum &> /dev/null; then
        print_info "Installing speedtest-cli via yum..."
        yum install -y speedtest-cli 2>/dev/null || print_warning "speedtest-cli installation failed (non-critical)"
    elif command -v dnf &> /dev/null; then
        print_info "Installing speedtest-cli via dnf..."
        dnf install -y speedtest-cli 2>/dev/null || print_warning "speedtest-cli installation failed (non-critical)"
    fi
}

# Function to show installation summary
show_summary() {
    echo
    print_success "🎉 Simple Speed Limiter installed successfully!"
    echo
    echo "📁 Installation Directory: $INSTALL_DIR"
    echo "🔗 System Command: simple-speed-limiter"
    echo "⚙️  Configuration File: $INSTALL_DIR/config.env"
    echo
    echo "📖 Quick Start:"
    echo "  1. Edit configuration: nano $INSTALL_DIR/config.env"
    echo "  2. Start speed limiting: simple-speed-limiter start"
    echo "  3. Check status: simple-speed-limiter status"
    echo "  4. Stop speed limiting: simple-speed-limiter stop"
    echo
    echo "🔧 Available Commands:"
    echo "  simple-speed-limiter start    # Start speed limiting"
    echo "  simple-speed-limiter stop     # Stop speed limiting"
    echo "  simple-speed-limiter restart  # Restart with new settings"
    echo "  simple-speed-limiter status   # Show current status"
    echo "  simple-speed-limiter test     # Test network speed"
    echo "  simple-speed-limiter config   # Show configuration"
    echo "  simple-speed-limiter help     # Show help"
    echo
    echo "📋 Next Steps:"
    echo "  1. Review and edit the configuration file:"
    echo "     nano $INSTALL_DIR/config.env"
    echo
    echo "  2. Find your network interface (if auto-detection failed):"
    echo "     ip link show"
    echo
    echo "  3. Start speed limiting:"
    echo "     simple-speed-limiter start"
    echo
    echo "📚 Documentation: $INSTALL_DIR/README.md"
    echo "🐛 Issues: https://github.com/V2rayZone/simple-speed-limiter/issues"
    echo
}

# Function to show uninstall instructions
show_uninstall() {
    echo "🗑️  To uninstall:"
    echo "  sudo rm -rf $INSTALL_DIR"
    echo "  sudo rm -f $BIN_LINK"
    echo
}

# Main installation function
main() {
    echo "🚀 Simple Speed Limiter - One-Line Installer"
    echo "================================================"
    echo
    
    check_root
    check_requirements
    create_install_dir
    download_files
    set_permissions
    create_symlink
    detect_interface
    install_optional_deps
    
    show_summary
    show_uninstall
    
    print_success "Installation completed! 🎉"
}

# Handle script interruption
trap 'print_error "Installation interrupted!"; exit 1' INT TERM

# Run main function
main "$@"