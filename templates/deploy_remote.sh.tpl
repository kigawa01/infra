#!/bin/bash

# Remote deployment script for Node Exporter
# Target: ${target_host}
# User: ${ssh_user}
# Key: ${ssh_key}

set -e

TARGET_HOST="${target_host}"
SSH_USER="${ssh_user}"
SSH_KEY="${ssh_key}"

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

log_info "Deploying Node Exporter to $TARGET_HOST"

# Check if SSH key exists
if [[ -n "$SSH_KEY" && ! -f "$SSH_KEY" ]]; then
    log_error "SSH key not found: $SSH_KEY"
    exit 1
fi

# Test SSH connection
log_info "Testing SSH connection to $TARGET_HOST"
if [[ -n "$SSH_KEY" ]]; then
    ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_HOST" "echo 'SSH connection successful'"
else
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_HOST" "echo 'SSH connection successful'"
fi

# Copy and execute installation script
log_info "Copying installation script to remote host"
SCRIPT_PATH="$(dirname "$0")/install_node_exporter.sh"

if [[ -n "$SSH_KEY" ]]; then
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SCRIPT_PATH" "$SSH_USER@$TARGET_HOST:/tmp/"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_HOST" "chmod +x /tmp/install_node_exporter.sh && sudo /tmp/install_node_exporter.sh"
else
    scp -o StrictHostKeyChecking=no "$SCRIPT_PATH" "$SSH_USER@$TARGET_HOST:/tmp/"
    ssh -o StrictHostKeyChecking=no "$SSH_USER@$TARGET_HOST" "chmod +x /tmp/install_node_exporter.sh && sudo /tmp/install_node_exporter.sh"
fi

log_info "Node Exporter deployment completed successfully!"
log_info "Access metrics at: http://$TARGET_HOST:9100/metrics"