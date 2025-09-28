#!/bin/bash

# Node Exporter installation script
# Version: ${node_exporter_version}
# Port: ${node_exporter_port}

set -e

NODE_EXPORTER_VERSION="${node_exporter_version}"
NODE_EXPORTER_PORT="${node_exporter_port}"
NODE_EXPORTER_USER="node_exporter"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "$${GREEN}[INFO]$${NC} $1"
}

log_warn() {
    echo -e "$${YELLOW}[WARN]$${NC} $1"
}

log_error() {
    echo -e "$${RED}[ERROR]$${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Starting Node Exporter installation..."

# Update package lists
log_info "Updating package lists"
apt-get update

# Install required packages
log_info "Installing required packages"
apt-get install -y wget tar systemd

# Create node_exporter user
if ! id "$NODE_EXPORTER_USER" &>/dev/null; then
    log_info "Creating user $NODE_EXPORTER_USER"
    useradd --system --no-create-home --shell /bin/false $NODE_EXPORTER_USER
else
    log_info "User $NODE_EXPORTER_USER already exists"
fi

# Download and install Node Exporter
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

log_info "Downloading Node Exporter v$NODE_EXPORTER_VERSION"
wget -q https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

log_info "Extracting Node Exporter"
tar xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

log_info "Installing Node Exporter binary"
cp node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter
chown $NODE_EXPORTER_USER:$NODE_EXPORTER_USER /usr/local/bin/node_exporter

# Create systemd service file
log_info "Creating systemd service file"
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:$NODE_EXPORTER_PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
log_info "Enabling and starting Node Exporter service"
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Check service status
if systemctl is-active --quiet node_exporter; then
    log_info "Node Exporter is running successfully"
    log_info "Metrics available at: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
else
    log_error "Node Exporter failed to start"
    exit 1
fi

# Check if firewall is active and open port if needed
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    log_info "Opening port $NODE_EXPORTER_PORT in UFW firewall"
    ufw allow $NODE_EXPORTER_PORT/tcp
fi

# Clean up
cd /
rm -rf $TEMP_DIR

log_info "Node Exporter installation completed successfully!"
log_info "Service status: $(systemctl is-active node_exporter)"
log_info "Access metrics at: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
