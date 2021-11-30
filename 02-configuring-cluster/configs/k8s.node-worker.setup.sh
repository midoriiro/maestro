#!/bin/bash

set -e

echo "Start worker node setup..."

if [[ -z "${SSH_USERNAME}" ]]; then
  echo "environment variable SSH_USERNAME not defined"
  exit 1
else
  SSH_USERNAME="${SSH_USERNAME}"
fi

if [[ -z "${SSH_PRIVATE_KEY_FILENAME}" ]]; then
  echo "environment variable SSH_PRIVATE_KEY_FILENAME not defined"
  exit 1
else
  SSH_PRIVATE_KEY_FILENAME="${SSH_PRIVATE_KEY_FILENAME}"
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

if [[ -z "${MASTER_IP}" ]]; then
  echo "environment variable MASTER_IP not defined"
  exit 1
else
  MASTER_IP="${MASTER_IP}"
fi

## Enable CRI-O
echo "  * Enable runtime service"
sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "  * Retrieve join information"
SSH_KEY_PATH=/home/"$SSH_USERNAME"/.ssh/"$SSH_PRIVATE_KEY_FILENAME"
CERTIFICATE_KEY=$(ssh -o "StrictHostKeyChecking no" -i "$SSH_KEY_PATH" "$SSH_USERNAME"@"$MASTER_IP" \
  "kubeadm certs certificate-key | tr -d '\n'"
)
ssh \
  -o "StrictHostKeyChecking no" \
  -i "$SSH_KEY_PATH" "$SSH_USERNAME"@"$MASTER_IP" \
  "sudo kubeadm init phase upload-certs --upload-certs --certificate-key $CERTIFICATE_KEY"
STDOUT=$(ssh -o "StrictHostKeyChecking no" -i "$SSH_KEY_PATH" "$SSH_USERNAME"@"$MASTER_IP" \
  "kubeadm token create --certificate-key $CERTIFICATE_KEY --print-join-command | awk '{print \$5, \$7}'"
)
IFS=' ' read -ra JOIN_INFORMATION <<< "$STDOUT"
TOKEN=${JOIN_INFORMATION[0]}
CERTIFICATE_HASH=${JOIN_INFORMATION[1]}

echo "  * Join master node"
sudo kubeadm join "$VIRTUAL_IP:6443" \
  --apiserver-advertise-address="$NODE_IP" \
  --token "$TOKEN" \
  --discovery-token-ca-cert-hash "$CERTIFICATE_HASH" \
  --v=5

echo "  * Copy kube settings"
ssh \
  -o "StrictHostKeyChecking no" \
  -i "/home/$SSH_USERNAME/.ssh/$SSH_PRIVATE_KEY_FILENAME" \
  "$SSH_USERNAME"@"$MASTER_IP" \
  "sudo chmod o+r /etc/kubernetes/admin.conf" \
  &> /dev/null
mkdir -p /home/"$SSH_USERNAME"/.kube &> /dev/null
scp  \
  -i "/home/$SSH_USERNAME/.ssh/$SSH_PRIVATE_KEY_FILENAME" \
  "$SSH_USERNAME"@"$MASTER_IP":/etc/kubernetes/admin.conf \
  /home/"$SSH_USERNAME"/.kube/config \
  &> /dev/null
ssh \
  -o "StrictHostKeyChecking no" \
  -i "/home/$SSH_USERNAME/.ssh/$SSH_PRIVATE_KEY_FILENAME" \
  "$SSH_USERNAME"@"$MASTER_IP" \
  "sudo chmod o-r /etc/kubernetes/admin.conf" \
  &> /dev/null
sudo chown -R $(id -u "$SSH_USERNAME"):$(id -g "$SSH_USERNAME") /home/"$SSH_USERNAME"/.kube &> /dev/null

set +e