#!/bin/bash

set -e

echo "Start master node setup..."

if [[ -z "${SSH_USERNAME}" ]]; then
  echo "environment variable SSH_USERNAME not defined"
  exit 1
else
  SSH_USERNAME="${SSH_USERNAME}"
fi

if [[ -z "${VIRTUAL_IP}" ]]; then
  echo "environment variable VIRTUAL_IP not defined"
  exit 1
else
  VIRTUAL_IP="${VIRTUAL_IP}"
fi

if [[ -z "${NODE_IP}" ]]; then
  echo "environment variable NODE_IP not defined"
  exit 1
else
  NODE_IP="${NODE_IP}"
fi

if [[ -z "${POD_NETWORK_CIDR}" ]]; then
  echo "environment variable POD_NETWORK_CIDR not defined"
  exit 1
else
  POD_NETWORK_CIDR="${POD_NETWORK_CIDR}"
fi

# Enable Kubernetes services
echo "  * Enable runtime service"
sudo systemctl daemon-reload &> /dev/null
sudo systemctl enable crio --now &> /dev/null

echo "  * Init master node"
sudo kubeadm init \
  --control-plane-endpoint="$VIRTUAL_IP:6443" \
  --upload-certs \
  --apiserver-advertise-address="$NODE_IP" \
  --pod-network-cidr="$POD_NETWORK_CIDR" \
  --v=5

echo "  * Install Calico"
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml &> /dev/null

echo "  * Copy kube settings"
mkdir -p /home/"$SSH_USERNAME"/.kube &> /dev/null
sudo cp -i /etc/kubernetes/admin.conf /home/"$SSH_USERNAME"/.kube/config &> /dev/null
sudo chown -R $(id -u "$SSH_USERNAME"):$(id -g "$SSH_USERNAME") /home/"$SSH_USERNAME"/.kube &> /dev/null

set +e