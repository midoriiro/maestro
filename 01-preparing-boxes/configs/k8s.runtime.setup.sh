#!/bin/bash

source k8s.common.setup.sh

runtime-setup() {
  common-setup

  echo "Start runtime setup..."

  echo "  * Setup kernel load modules at bootup"
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf &> /dev/null
overlay
br_netfilter
EOF

  # Check modules exist (TODO: do the check)
  sudo modprobe overlay &> /dev/null
  sudo modprobe br_netfilter &> /dev/null

  echo "  * Setup persistent system parameters at bootup"
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf &> /dev/null
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

  sudo sysctl --system &> /dev/null
}
