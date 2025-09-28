#!/bin/bash
set -e

echo "Starting nginx installation..."

# Set non-interactive frontend (Debian handbook recommended)
export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update
#rm /etc/nginx/nginx.conf
# Install nginx with official Debian handbook non-interactive options
#yes '' | apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install nginx

# Enable and start nginx service
systemctl enable nginx
systemctl start nginx

# Test nginx configuration
nginx -t


echo "Nginx installation completed successfully!"
echo "You can access the web server at http://$(hostname -I | awk '{print $1}')"
