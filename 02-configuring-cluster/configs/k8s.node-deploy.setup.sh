#!/bin/bash

set -e

echo "Start deploy node setup..."

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

if [[ -z "${NODES}" ]]; then
  echo "environment variable NODES not defined"
  exit 1
else
  NODES="${NODES}"
fi

if [[ -z "${MASTER_IP}" ]]; then
  echo "environment variable MASTER_IP not defined"
  exit 1
else
  MASTER_IP="${MASTER_IP}"
fi

echo "  * SSH connections"

IFS="," read -a NODES <<< "$NODES"

for NODE in "${NODES[@]}"
do
  ssh -o "StrictHostKeyChecking no" -i "/home/$SSH_USERNAME/.ssh/$SSH_PRIVATE_KEY_FILENAME" "$SSH_USERNAME"@"$NODE" &> /dev/null
done

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
