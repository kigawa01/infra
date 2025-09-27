#!/bin/bash
set -e

echo "Starting nginx installation..."

# Update package list
apt-get update

# Install nginx
apt-get install -y nginx

# Enable and start nginx service
systemctl enable nginx
systemctl start nginx

# Test nginx configuration
nginx -t

# Check nginx status
systemctl status nginx

echo "Nginx installation completed successfully!"
echo "You can access the web server at http://$(hostname -I | awk '{print $1}')"