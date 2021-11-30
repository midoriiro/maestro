#!/bin/bash

set -e

source k8s.runtime.setup.sh

runtime-setup

echo "Start worker node setup..."

echo "  * Set specific kubernetes worker node ports to allow connection"
## Kubelet API
sudo firewall-cmd --permanent --zone=public --add-port=10250/tcp &> /dev/null
## NodePort Services
sudo firewall-cmd --permanent --zone=public --add-port=30000-32767/tcp &> /dev/null
## Add masquerade
sudo firewall-cmd --permanent --add-masquerade &> /dev/null
## Reload configuration
sudo firewall-cmd --reload &> /dev/null

echo "  * Install Kubernetes runtime"
sudo apt-get install -y cri-o cri-o-runc &> /dev/null

echo "  * Install Kubernetes worker node specific packages"
sudo apt-get install -y kubelet kubeadm kubectl &> /dev/null
sudo apt-mark hold kubelet kubeadm kubectl &> /dev/null

echo "  * Pull Kubernetes images"
sudo systemctl daemon-reload &> /dev/null
sudo systemctl enable crio --now &> /dev/null
sudo kubeadm config images pull &> /dev/null
sudo systemctl disable crio &> /dev/null

set +e