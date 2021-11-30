#!/bin/bash

set -e

source k8s.runtime.setup.sh

runtime-setup

echo "Start master node setup..."

echo "  * Set specific kubernetes master node ports to allow connection"
## Kubernetes API Server
sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp &> /dev/null
## ETCD client/server
sudo firewall-cmd --permanent --zone=public --add-port=2379-2380/tcp &> /dev/null
## Kubelet API
sudo firewall-cmd --permanent --zone=public --add-port=10250/tcp &> /dev/null
## Kube Scheduler
sudo firewall-cmd --permanent --zone=public --add-port=10259/tcp &> /dev/null
## Kube Controller Manager
sudo firewall-cmd --permanent --zone=public --add-port=10257/tcp &> /dev/null
## Add masquerade
sudo firewall-cmd --permanent --add-masquerade &> /dev/null
## Reload configuration
sudo firewall-cmd --reload &> /dev/null

echo "  * Install Kubernetes runtime"
sudo apt-get install -y cri-o cri-o-runc &> /dev/null

echo "  * Install Kubernetes master node specific packages"
sudo apt-get install -y kubelet kubeadm kubectl &> /dev/null
sudo apt-mark hold kubelet kubeadm kubectl &> /dev/null

echo "  * Pull Kubernetes images"
sudo systemctl daemon-reload &> /dev/null
sudo systemctl enable crio --now &> /dev/null
sudo kubeadm config images pull &> /dev/null
sudo systemctl disable crio &> /dev/null

set +e