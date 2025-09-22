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
rsync -avz ${ssh_options} --rsync-path="rsync" kubernetes/manifests/ "${ssh_user}@${target_host}:${remote_manifests_dir}/"

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
    
    # Apply all manifest files dynamically
    deployed_deployments=()
    for yaml_file in \$(find . -name '*.yml' -o -name '*.yaml' | sort); do
        # Skip nginx-exporter.yml if not enabled
        if [[ \"\$yaml_file\" == *\"nginx-exporter.yml\"* ]] && [ '${apply_nginx_exporter}' != 'true' ]; then
            echo \"Skipping \$yaml_file (nginx-exporter disabled)\"
            continue
        fi

        echo \"Applying \$yaml_file\"
        kubectl apply \$KUBECTL_CONTEXT_CMD -f \"\$yaml_file\"

        # Check if this file contains a Deployment and collect namespace/name
        if grep -q \"kind: Deployment\" \"\$yaml_file\"; then
            namespace=\$(grep -A 10 \"kind: Deployment\" \"\$yaml_file\" | grep \"namespace:\" | head -1 | awk '{print \$2}' || echo \"default\")
            name=\$(grep -A 10 \"kind: Deployment\" \"\$yaml_file\" | grep \"name:\" | head -1 | awk '{print \$2}')
            if [[ -n \"\$name\" ]]; then
                deployed_deployments+=(\"\$namespace/\$name\")
            fi
        fi
    done

    # Restart all deployments to ensure new images are pulled
    if [[ \$${#deployed_deployments[@]} -gt 0 ]]; then
        echo \"Restarting deployments to pick up new images...\"
        # Remove duplicates from the array
        unique_deployments=(\$(printf '%s\n' \"\$${deployed_deployments[@]}\" | sort -u))
        for deployment in \"\$${unique_deployments[@]}\"; do
            namespace=\$(echo \"\$deployment\" | cut -d'/' -f1)
            name=\$(echo \"\$deployment\" | cut -d'/' -f2)
            echo \"Restarting deployment \$name in namespace \$namespace\"
            kubectl rollout restart \$KUBECTL_CONTEXT_CMD deployment \"\$name\" -n \"\$namespace\"
            # Add a small delay to avoid kubectl conflicts
            sleep 1
        done
    fi
"

log_info "Kubernetes manifests applied successfully!"