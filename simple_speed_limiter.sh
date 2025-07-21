#!/bin/bash

# Simple Speed Limiter for Ubuntu VPS
# Uses tc (traffic control) to limit bandwidth

set -e

# Configuration file path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/config.env"

# Default values
INTERFACE="eth0"
DOWNLOAD_LIMIT_MBPS="10"
UPLOAD_LIMIT_MBPS="10"
IFB_INTERFACE="ifb0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        print_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        print_warning "Configuration file not found. Using default values."
        print_info "Creating default configuration file..."
        create_default_config
    fi
}

# Function to create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# Simple Speed Limiter Configuration
# Network interface (use 'ip link show' to see available interfaces)
INTERFACE="eth0"

# Download limit in Mbps (ingress traffic)
DOWNLOAD_LIMIT_MBPS="10"

# Upload limit in Mbps (egress traffic)
UPLOAD_LIMIT_MBPS="10"

# IFB interface for ingress shaping (usually ifb0)
IFB_INTERFACE="ifb0"
EOF
    print_success "Default configuration created at $CONFIG_FILE"
}

# Function to convert Mbps to Kbps for tc
mbps_to_kbps() {
    echo "$(($1 * 1000))kbit"
}

# Function to setup IFB module
setup_ifb() {
    print_info "Setting up IFB module for ingress shaping..."
    
    # Load IFB module if not already loaded
    if ! lsmod | grep -q ifb; then
        modprobe ifb numifbs=1
    fi
    
    # Bring up IFB interface
    ip link set dev "$IFB_INTERFACE" up
}

# Function to start speed limiting
start_limiting() {
    print_info "Starting speed limiting on interface $INTERFACE"
    print_info "Download limit: ${DOWNLOAD_LIMIT_MBPS}Mbps, Upload limit: ${UPLOAD_LIMIT_MBPS}Mbps"
    
    # Convert Mbps to Kbps
    DOWNLOAD_KBPS=$(mbps_to_kbps $DOWNLOAD_LIMIT_MBPS)
    UPLOAD_KBPS=$(mbps_to_kbps $UPLOAD_LIMIT_MBPS)
    
    # Setup IFB for ingress shaping
    setup_ifb
    
    # Clear existing rules
    stop_limiting 2>/dev/null || true
    
    print_info "Setting up egress (upload) limiting..."
    # Setup egress (upload) limiting
    tc qdisc add dev "$INTERFACE" root handle 1: htb default 30
    tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate "$UPLOAD_KBPS"
    tc class add dev "$INTERFACE" parent 1:1 classid 1:10 htb rate "$UPLOAD_KBPS" ceil "$UPLOAD_KBPS"
    tc filter add dev "$INTERFACE" parent 1: protocol ip prio 1 u32 match ip src 0.0.0.0/0 flowid 1:10
    
    print_info "Setting up ingress (download) limiting..."
    # Setup ingress (download) limiting using IFB
    tc qdisc add dev "$INTERFACE" ingress
    tc filter add dev "$INTERFACE" parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev "$IFB_INTERFACE"
    
    # Apply shaping on IFB interface
    tc qdisc add dev "$IFB_INTERFACE" root handle 1: htb default 30
    tc class add dev "$IFB_INTERFACE" parent 1: classid 1:1 htb rate "$DOWNLOAD_KBPS"
    tc class add dev "$IFB_INTERFACE" parent 1:1 classid 1:10 htb rate "$DOWNLOAD_KBPS" ceil "$DOWNLOAD_KBPS"
    tc filter add dev "$IFB_INTERFACE" parent 1: protocol ip prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:10
    
    print_success "Speed limiting activated successfully!"
    print_info "Upload limit: $UPLOAD_KBPS on $INTERFACE"
    print_info "Download limit: $DOWNLOAD_KBPS via $IFB_INTERFACE"
}

# Function to stop speed limiting
stop_limiting() {
    print_info "Stopping speed limiting..."
    
    # Remove egress qdisc
    tc qdisc del dev "$INTERFACE" root 2>/dev/null || true
    
    # Remove ingress qdisc
    tc qdisc del dev "$INTERFACE" ingress 2>/dev/null || true
    
    # Remove IFB qdisc
    tc qdisc del dev "$IFB_INTERFACE" root 2>/dev/null || true
    
    # Bring down IFB interface
    ip link set dev "$IFB_INTERFACE" down 2>/dev/null || true
    
    print_success "Speed limiting stopped successfully!"
}

# Function to show current status
show_status() {
    print_info "Current Traffic Control Status:"
    echo
    
    print_info "Egress (Upload) Rules on $INTERFACE:"
    tc qdisc show dev "$INTERFACE" 2>/dev/null || print_warning "No egress rules found"
    echo
    
    print_info "Ingress (Download) Rules on $INTERFACE:"
    tc filter show dev "$INTERFACE" parent ffff: 2>/dev/null || print_warning "No ingress rules found"
    echo
    
    print_info "IFB Interface Status:"
    ip link show "$IFB_INTERFACE" 2>/dev/null || print_warning "IFB interface not found"
    echo
    
    print_info "IFB Traffic Control Rules:"
    tc qdisc show dev "$IFB_INTERFACE" 2>/dev/null || print_warning "No IFB rules found"
}

# Function to test speed
test_speed() {
    print_info "Testing network speed..."
    
    if command -v speedtest-cli &> /dev/null; then
        speedtest-cli
    elif command -v curl &> /dev/null; then
        print_info "Using curl for basic speed test..."
        curl -o /dev/null -s -w "Download Speed: %{speed_download} bytes/sec\n" http://speedtest.wdc01.softlayer.com/downloads/test10.zip
    else
        print_warning "No speed test tools found. Install speedtest-cli for better testing."
        print_info "You can install it with: apt install speedtest-cli"
    fi
}

# Function to show help
show_help() {
    echo "Simple Speed Limiter for Ubuntu VPS"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  start     Start speed limiting"
    echo "  stop      Stop speed limiting"
    echo "  restart   Restart speed limiting"
    echo "  status    Show current status"
    echo "  test      Test network speed"
    echo "  config    Show current configuration"
    echo "  help      Show this help message"
    echo
    echo "Configuration is loaded from: $CONFIG_FILE"
    echo
}

# Function to show configuration
show_config() {
    print_info "Current Configuration:"
    echo "Interface: $INTERFACE"
    echo "Download Limit: ${DOWNLOAD_LIMIT_MBPS}Mbps"
    echo "Upload Limit: ${UPLOAD_LIMIT_MBPS}Mbps"
    echo "IFB Interface: $IFB_INTERFACE"
    echo "Config File: $CONFIG_FILE"
}

# Main script logic
main() {
    check_root
    load_config
    
    case "${1:-help}" in
        start)
            start_limiting
            ;;
        stop)
            stop_limiting
            ;;
        restart)
            stop_limiting
            sleep 1
            start_limiting
            ;;
        status)
            show_status
            ;;
        test)
            test_speed
            ;;
        config)
            show_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
