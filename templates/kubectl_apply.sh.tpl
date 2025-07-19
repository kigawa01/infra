#!/bin/bash

# Kubectl Apply Script for Kubernetes Manifests
# Target: ${target_host}
# User: ${ssh_user}
# Key: ${ssh_key}
# Remote Manifests Directory: ${remote_manifests_dir}
# Kubectl Context: ${kubectl_context}

set -e

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

log_info "Applying Kubernetes manifests via SSH to ${target_host}"

# Create remote directory for manifests if it doesn't exist
log_info "Creating remote directory for manifests"
ssh ${ssh_options} "${ssh_user}@${target_host}" "mkdir -p ${remote_manifests_dir}"

# Copy all manifest files to the remote host
log_info "Copying Kubernetes manifests to remote host"
scp ${ssh_options} ${manifests_to_copy} "${ssh_user}@${target_host}:${remote_manifests_dir}/"

# Apply the manifests using kubectl on the remote host
log_info "Applying Kubernetes manifests on remote host"

# Set kubectl context if specified
KUBECTL_CONTEXT_CMD=""
if [[ -n "${kubectl_context}" ]]; then
    KUBECTL_CONTEXT_CMD="--context=${kubectl_context}"
fi

# Apply each manifest file
ssh ${ssh_options} "${ssh_user}@${target_host}" "
    set -e
    cd ${remote_manifests_dir}
    
    # Apply ingress manifest
    if [ -f 'ingress.yml' ]; then
        echo 'Applying ingress.yml'
        kubectl apply $KUBECTL_CONTEXT_CMD -f ingress.yml
    fi
    
    # Apply prometheus manifest
    if [ -f 'prometheus.yml' ]; then
        echo 'Applying prometheus.yml'
        kubectl apply $KUBECTL_CONTEXT_CMD -f prometheus.yml
    fi
    
    # Apply pve-exporter manifest
    if [ -f 'pve-exporter.yml' ]; then
        echo 'Applying pve-exporter.yml'
        kubectl apply $KUBECTL_CONTEXT_CMD -f pve-exporter.yml
    fi
    
    # Apply nginx-exporter manifest if enabled
    if [ -f 'nginx-exporter.yml' ] && [ '${apply_nginx_exporter}' = 'true' ]; then
        echo 'Applying nginx-exporter.yml'
        kubectl apply $KUBECTL_CONTEXT_CMD -f nginx-exporter.yml
    fi
"

log_info "Kubernetes manifests applied successfully!"