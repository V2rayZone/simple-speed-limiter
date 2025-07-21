# Simple Speed Limiter for Ubuntu VPS

![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/badge/Version-1.0-brightgreen.svg)

A minimal script to enforce outbound/inbound speed limits on Ubuntu VPS using traffic control (`tc`) and intermediate functional block (`ifb`) interfaces.

## 🎯 Features

- **Bidirectional Speed Control**: Limit both download (ingress) and upload (egress) speeds
- **One-Line Installation**: Install with a single command
- **Easy Configuration**: Simple environment file for settings
- **Ubuntu Optimized**: Designed for Ubuntu 20.04/22.04 VPS
- **Standard Tools**: Uses `tc`, `ifb`, and `iptables` - no external dependencies
- **Flexible Control**: Easy enable/disable and speed adjustment
- **Status Monitoring**: Check current limits and test speeds
- **System Integration**: Global command available after installation

## 📋 Requirements

### System Requirements
- Ubuntu 20.04/22.04 (or compatible Linux distribution)
- Root access
- Network interface (e.g., `eth0`, `ens3`)
- `curl` (for installation)

### Required Packages
```bash
# Usually pre-installed on Ubuntu
sudo apt update
sudo apt install iproute2 kmod curl

# Optional: For speed testing
sudo apt install speedtest-cli
```

## 🚀 Installation

### One-Line Installation (Recommended)

Install Simple Speed Limiter with a single command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/V2rayZone/simple-speed-limiter/main/install.sh)
```

This will:
- ✅ Download all required files to `/opt/simple-speed-limiter/`
- ✅ Make the script executable
- ✅ Create a system-wide command `simple-speed-limiter`
- ✅ Auto-detect your network interface
- ✅ Install optional dependencies

### Manual Installation

```bash
# Clone the repository
sudo git clone https://github.com/V2rayZone/simple-speed-limiter.git /opt/simple-speed-limiter

# Make the script executable
sudo chmod +x /opt/simple-speed-limiter/simple_speed_limiter.sh

# Create system-wide command (optional)
sudo ln -s /opt/simple-speed-limiter/simple_speed_limiter.sh /usr/local/bin/simple-speed-limiter
```

## 🚀 Quick Start

### 1. Configure Speed Limits
Edit the configuration file:
```bash
sudo nano /opt/simple-speed-limiter/config.env
```

Example configuration:
```bash
# Network interface (find yours with: ip link show)
INTERFACE="eth0"

# Speed limits in Mbps
DOWNLOAD_LIMIT_MBPS="50"    # 50 Mbps download limit
UPLOAD_LIMIT_MBPS="25"      # 25 Mbps upload limit

# IFB interface (usually ifb0)
IFB_INTERFACE="ifb0"
```

### 2. Start Speed Limiting
```bash
sudo simple-speed-limiter start
```

## 📖 Usage

### Available Commands

```bash
# Start speed limiting
sudo simple-speed-limiter start

# Stop speed limiting
sudo simple-speed-limiter stop

# Restart with new settings
sudo simple-speed-limiter restart

# Check current status
sudo simple-speed-limiter status

# Test network speed
sudo simple-speed-limiter test

# Show current configuration
sudo simple-speed-limiter config

# Show help
sudo simple-speed-limiter help
```

### Example Usage Session

```bash
# Check your network interface
ip link show

# Edit configuration
sudo nano /opt/simple-speed-limiter/config.env

# Start limiting
sudo simple-speed-limiter start
[INFO] Loading configuration from /opt/simple-speed-limiter/config.env
[INFO] Starting speed limiting on interface eth0
[INFO] Download limit: 10Mbps, Upload limit: 10Mbps
[SUCCESS] Speed limiting activated successfully!

# Check status
sudo simple-speed-limiter status

# Test speed
sudo simple-speed-limiter test

# Stop when done
sudo simple-speed-limiter stop
```

## ⚙️ Configuration Options

| Parameter | Description | Example | Notes |
|-----------|-------------|---------|-------|
| `INTERFACE` | Network interface name | `eth0`, `ens3` | Use `ip link show` to find yours |
| `DOWNLOAD_LIMIT_MBPS` | Download speed limit | `50` | In Megabits per second |
| `UPLOAD_LIMIT_MBPS` | Upload speed limit | `25` | In Megabits per second |
| `IFB_INTERFACE` | IFB interface for ingress | `ifb0` | Usually ifb0, ifb1, etc. |

### Speed Conversion Reference
- 1 Mbps = 1,000 Kbps = 125 KB/s
- 10 Mbps = 10,000 Kbps = 1.25 MB/s
- 100 Mbps = 100,000 Kbps = 12.5 MB/s

## 🔧 How It Works

### Technical Overview

1. **Egress (Upload) Control**: Uses HTB (Hierarchical Token Bucket) qdisc on the main interface
2. **Ingress (Download) Control**: Uses IFB (Intermediate Functional Block) interface to redirect and shape incoming traffic
3. **Traffic Classification**: Uses u32 filters to match and direct traffic to appropriate classes

### Traffic Flow
```
Outgoing Traffic (Upload):
Application → Interface → HTB Qdisc → Rate Limiting → Network

Incoming Traffic (Download):
Network → Interface → Ingress Filter → IFB Interface → HTB Qdisc → Rate Limiting → Application
```

## 🧪 Testing and Verification

### Speed Test Methods

1. **Using speedtest-cli** (Recommended):
```bash
sudo apt install speedtest-cli
speedtest-cli
```

2. **Using curl**:
```bash
# Download test
curl -o /dev/null -s -w "Download Speed: %{speed_download} bytes/sec\n" http://speedtest.wdc01.softlayer.com/downloads/test10.zip

# Upload test (if server supports)
curl -T largefile.zip -s -w "Upload Speed: %{speed_upload} bytes/sec\n" ftp://speedtest.server.com/upload/
```

3. **Using iperf3**:
```bash
sudo apt install iperf3
# Server mode
iperf3 -s
# Client mode (from another machine)
iperf3 -c your-vps-ip
```

### Verification Steps

1. **Before applying limits**:
```bash
speedtest-cli  # Note the baseline speeds
```

2. **Apply speed limits**:
```bash
sudo ./simple_speed_limiter.sh start
```

3. **Test with limits**:
```bash
sudo ./simple_speed_limiter.sh test
```

4. **Check tc status**:
```bash
sudo ./simple_speed_limiter.sh status
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. "Interface not found" Error
```bash
# Find your interface name
ip link show
# Update config.env with correct interface name
```

#### 2. "Permission denied" Error
```bash
# Ensure you're running as root
sudo ./simple_speed_limiter.sh start
```

#### 3. "IFB module not found" Error
```bash
# Load IFB module manually
sudo modprobe ifb numifbs=1
# Or install linux-modules-extra
sudo apt install linux-modules-extra-$(uname -r)
```

#### 4. Speed limits not working
```bash
# Check if rules are applied
sudo tc qdisc show
sudo tc class show dev eth0

# Restart the limiter
sudo ./simple_speed_limiter.sh restart
```

#### 5. Can't remove existing rules
```bash
# Force clean all tc rules
sudo tc qdisc del dev eth0 root 2>/dev/null || true
sudo tc qdisc del dev eth0 ingress 2>/dev/null || true
sudo tc qdisc del dev ifb0 root 2>/dev/null || true
```

### Debug Mode

For detailed troubleshooting, you can modify the script to add debug output:
```bash
# Add this line after #!/bin/bash
set -x  # Enable debug mode
```

## 🔄 Persistence and Automation

### Auto-start on Boot (Optional)

Create a systemd service:

```bash
sudo nano /etc/systemd/system/speed-limiter.service
```

```ini
[Unit]
Description=Simple Speed Limiter
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/simple-speed-limiter/simple_speed_limiter.sh start
ExecStop=/opt/simple-speed-limiter/simple_speed_limiter.sh stop
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable speed-limiter.service
sudo systemctl start speed-limiter.service
```

### Cron Job Alternative

```bash
# Add to root crontab
sudo crontab -e

# Add this line to start on reboot
@reboot /opt/simple-speed-limiter/simple_speed_limiter.sh start
```

## 📊 Monitoring and Logs

### Real-time Traffic Monitoring

```bash
# Monitor interface traffic
watch -n 1 'cat /proc/net/dev | grep eth0'

# Monitor tc statistics
watch -n 1 'tc -s qdisc show dev eth0'

# Monitor IFB interface
watch -n 1 'tc -s qdisc show dev ifb0'
```

### Log Traffic Statistics

```bash
# Create a simple monitoring script
cat > monitor_traffic.sh << 'EOF'
#!/bin/bash
while true; do
    echo "$(date): $(tc -s qdisc show dev eth0 | grep 'Sent')" >> /var/log/speed-limiter.log
    sleep 60
done
EOF

chmod +x monitor_traffic.sh
nohup ./monitor_traffic.sh &
```

## 🚀 Advanced Usage

### Multiple Speed Classes

For more complex scenarios, you can modify the script to create multiple traffic classes:

```bash
# Example: Different limits for different traffic types
# HTTP traffic: 10 Mbps
# SSH traffic: 1 Mbps
# Other traffic: 5 Mbps
```

### Integration with Monitoring Tools

The script can be integrated with monitoring tools like:
- Prometheus + Grafana
- Zabbix
- Nagios
- Custom monitoring scripts

## 📝 License

This project is released under the MIT License. Feel free to modify and distribute.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section
2. Verify your system meets the requirements
3. Test with default configuration first
4. Check system logs: `journalctl -xe`

---

**Note**: This tool is designed for legitimate bandwidth management and testing purposes. Always ensure you have proper authorization before implementing traffic shaping on any network.