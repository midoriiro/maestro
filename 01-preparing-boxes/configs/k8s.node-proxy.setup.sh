#!/bin/bash

set -e

source k8s.common.setup.sh

common-setup

echo "Start proxy node setup..."

cat <<EOF | sudo tee /etc/sysctl.d/vip.conf &> /dev/null
net.ipv4.ip_nonlocal_bind = 1
EOF

echo "  * Set specific kubernetes proxy node ports to allow connection"
## Kubernetes API Server
sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp &> /dev/null
## Https
sudo firewall-cmd --permanent --zone=public --add-port=443/tcp &> /dev/null
## Add masquerade
sudo firewall-cmd --permanent --add-masquerade &> /dev/null
## Reload configuration
sudo firewall-cmd --reload &> /dev/null

echo "  * Install Kubernetes haproxy"
sudo apt-get install -y haproxy keepalived &> /dev/null
sudo apt-mark hold haproxy keepalived &> /dev/null

set +e