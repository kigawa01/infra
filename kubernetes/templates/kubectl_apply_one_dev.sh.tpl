#!/bin/bash
set -e

# SSH configuration
TARGET_HOST="${target_host}"
SSH_USER="${ssh_user}"
SSH_OPTIONS="${ssh_options}"
REMOTE_MANIFESTS_DIR="${remote_manifests_dir}/one/dev"
KUBECTL_CONTEXT="${kubectl_context}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "$${GREEN}Deploying one/dev Kubernetes manifests via SSH...$${NC}"

# Create remote directory
ssh $SSH_OPTIONS $SSH_USER@$TARGET_HOST "mkdir -p $REMOTE_MANIFESTS_DIR"

# Copy manifests to remote host
echo -e "$${BLUE}Copying manifests to remote host...$${NC}"
scp $SSH_OPTIONS ${manifests_to_copy} $SSH_USER@$TARGET_HOST:$REMOTE_MANIFESTS_DIR/

# Apply manifests on remote host
echo -e "$${BLUE}Applying Kubernetes manifests on remote host...$${NC}"
ssh $SSH_OPTIONS $SSH_USER@$TARGET_HOST bash << 'EOF'
set -e

# Set kubectl context if provided
if [ -n "${kubectl_context}" ]; then
    kubectl config use-context ${kubectl_context}
fi

# Apply manifests in order (secrets first, then deployments, then services)
echo "Applying harbor account secret..."
kubectl apply -f ${remote_manifests_dir}/one/dev/harbor-account-secret.yml

echo "Applying MC deployment..."
kubectl apply -f ${remote_manifests_dir}/one/dev/mc-deploy.yml

echo "Applying MC service..."
kubectl apply -f ${remote_manifests_dir}/one/dev/mc-svc.yml

echo "All one/dev manifests applied successfully!"
EOF

echo -e "$${GREEN}one/dev manifests deployment completed successfully!$${NC}"