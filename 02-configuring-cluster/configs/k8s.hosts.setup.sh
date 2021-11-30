#!/bin/bash

set -e

echo "Start setting hosts setup..."

if [[ -z "${HOSTS}" ]]; then
  echo "environment variable HOSTS not defined"
  exit 1
else
  HOSTS="${HOSTS}"
fi

IFS="," read -a HOSTS <<< "$HOSTS"

cat <<EOF | sudo tee /etc/hosts &> /dev/null
127.0.0.1       localhost
127.0.1.1       Debian.home     Debian

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
$(for HOST in "${HOSTS[@]}"
do
  printf '%s\n' "$HOST"
done)
EOF

set +e



