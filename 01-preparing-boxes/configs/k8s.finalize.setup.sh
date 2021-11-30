#!/bin/bash

set -e

echo "Start finalize nodes setup..."

if [[ -z "${SSH_USERNAME}" ]]; then
  echo "environment variable SSH_USERNAME not defined"
  exit 1
else
  SSH_USERNAME="${SSH_USERNAME}"
fi

if [[ -z "${SSH_PUBLIC_KEY}" ]]; then
  echo "environment variable SSH_PUBLIC_KEY not defined"
  exit 1
else
  SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY}"
fi

if [[ -z "${SSH_PRIVATE_KEY}" ]]; then
  echo "environment variable SSH_PRIVATE_KEY not defined"
  exit 1
else
  SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY}"
fi

echo "  * Set ssh connection to only accept ssh keys"
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config &> /dev/null
sudo sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config &> /dev/null

echo "  * Set user ssh key"
sudo cat /home/"$SSH_USERNAME"/.ssh/"$SSH_PUBLIC_KEY" | sudo tee /home/"$SSH_USERNAME"/.ssh/authorized_keys &> /dev/null
sudo chmod 400 /home/"$SSH_USERNAME"/.ssh/"$SSH_PUBLIC_KEY" &> /dev/null
sudo chmod 400 /home/"$SSH_USERNAME"/.ssh/"$SSH_PRIVATE_KEY" &> /dev/null

echo "  * Disable wait in grub menu"
sudo sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub &> /dev/null
sudo sed -i 's/^GRUB_HIDDEN_TIMEOUT=.*/GRUB_HIDDEN_TIMEOUT=0/' /etc/default/grub &> /dev/null
sudo sed -i 's/^GRUB_HIDDEN_TIMEOUT_QUIET=.*/GRUB_HIDDEN_TIMEOUT_QUIET=true/' /etc/default/grub &> /dev/null
sudo update-grub

set +e