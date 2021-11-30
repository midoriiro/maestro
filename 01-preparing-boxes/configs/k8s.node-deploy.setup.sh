#!/bin/bash

set -e

source k8s.common.setup.sh

common-setup

echo "Start deploy node setup..."

echo "  * Install Helm and Kubectl packages"
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add - &> /dev/null
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list &> /dev/null
sudo apt-get update &> /dev/null
sudo apt-get install helm kubectl -y &> /dev/null
sudo apt-mark hold helm kubectl &> /dev/null

set +e
