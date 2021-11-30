#!/bin/bash

if [[ -z "${KUBERNETES_OS_NAME}" ]]; then
  echo "environment variable KUBERNETES_OS_NAME not defined"
  exit 1
else
  OS="${KUBERNETES_OS_NAME}"
fi

if [[ -z "${KUBERNETES_VERSION}" ]]; then
  echo "environment variable KUBERNETES_VERSION not defined"
  exit 1
else
  VERSION="${KUBERNETES_VERSION}"
fi

common-setup() {
  echo "Start common setup..."

  # Disable swap :
  # Swap partition should not be exist by design.
  # But in case this partition exist the following code disable swap at kernel level
  echo "  * Disable swap partition"
  sudo sed -i '/swap/d' /etc/fstab
  sudo swapoff -a

  echo "  * Setup kernel load modules at bootup"
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf &> /dev/null
br_netfilter
EOF

  # Check module exist (TODO: do the check)
  sudo modprobe br_netfilter &> /dev/null

  echo "  * Setup persistent system parameters at bootup"
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf &> /dev/null
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
EOF

  sudo sysctl --system &> /dev/null

  echo "  * Install common dependencies"
  sudo apt-get update &> /dev/null
  sudo apt-get install -y apt-transport-https ca-certificates curl wget netcat firewalld gnupg &> /dev/null

  echo "  * Setup CRI-O repository"
  echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list &> /dev/null
  echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:"$VERSION".list &> /dev/null
  sudo curl -sL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:"$VERSION"/"$OS"/Release.key | sudo apt-key add - &> /dev/null
  sudo curl -sL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/"$OS"/Release.key | sudo apt-key add - &> /dev/null

  echo "  * Setup Kubernetes repository"
  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &> /dev/null
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list &> /dev/null

  echo "  * Update repository"
  sudo apt-get update &> /dev/null

  echo "  * Setup firewall and allow ssh connection"
  sudo firewall-cmd --permanent --add-service=ssh &> /dev/null
  sudo systemctl enable firewalld &> /dev/null
}
