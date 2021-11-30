#!/bin/bash

set -e

echo "Start proxy node setup..."

if [[ -z "${VIRTUAL_IP}" ]]; then
  echo "environment variable VIRTUAL_IP not defined"
  exit 1
else
  VIRTUAL_IP="${VIRTUAL_IP}"
fi

if [[ -z "${NETWORK_INTERFACE}" ]]; then
  echo "environment variable NETWORK_INTERFACE not defined"
  exit 1
else
  NETWORK_INTERFACE="${NETWORK_INTERFACE}"
fi

if [[ -z "${STATE}" ]]; then
  echo "environment variable STATE not defined"
  exit 1
else
  STATE="${STATE}"
fi

if [[ -z "${PRIORITY}" ]]; then
  echo "environment variable PRIORITY not defined"
  exit 1
else
  PRIORITY="${PRIORITY}"
fi

if [[ -z "${MASTER_NODES}" ]]; then
  echo "environment variable MASTER_NODES not defined"
  exit 1
else
  MASTER_NODES="${MASTER_NODES}"
fi

IFS="," read -a MASTER_NODES <<< "$MASTER_NODES"

echo "  * Setup haproxy config file"

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg &> /dev/null
global
  log /dev/log local0
  log /dev/log local1 notice
  daemon

defaults
  log global
  mode    http
  option  httplog
  option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
  errorfile 400 /etc/haproxy/errors/400.http
  errorfile 403 /etc/haproxy/errors/403.http
  errorfile 408 /etc/haproxy/errors/408.http
  errorfile 500 /etc/haproxy/errors/500.http
  errorfile 502 /etc/haproxy/errors/502.http
  errorfile 503 /etc/haproxy/errors/503.http
  errorfile 504 /etc/haproxy/errors/504.http

frontend apiserver
  bind $VIRTUAL_IP:6443
  mode tcp
  option tcplog
  use_backend apiserver

backend apiserver
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
$(for NODE in "${MASTER_NODES[@]}"
do
  printf '%s\n' "$(printf '%*s' 2)server $NODE:6443 check"
done)
EOF

echo "  * Setup keepalived config files"

cat <<EOF | sudo tee /etc/keepalived/check_haproxy.sh &> /dev/null
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q ${VIRTUAL_IP}; then
    curl --silent --max-time 2 --insecure https://${VIRTUAL_IP}:6443/ -o /dev/null || errorExit "Error GET https://${VIRTUAL_IP}:6443/"
fi
EOF

sudo chmod +x /etc/keepalived/check_haproxy.sh

cat <<EOF | sudo tee /etc/keepalived/keepalived.conf &> /dev/null
global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_haproxy  {
  script "/etc/keepalived/check_haproxy.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance haproxy-vip {
    state ${STATE^^}
    interface $NETWORK_INTERFACE
    virtual_router_id 51
    priority $PRIORITY
    authentication {
        auth_type PASS
        auth_pass 42
    }
    virtual_ipaddress {
        $VIRTUAL_IP/24
    }
    track_script {
        check_haproxy
    }
}
EOF

sudo sysctl --system &> /dev/null

## Enable HAProxy services
echo "  * Enable proxy services"
sudo systemctl daemon-reload &> /dev/null
sudo systemctl enable keepalived &> /dev/null
sudo systemctl restart keepalived &> /dev/null
sudo systemctl enable haproxy &> /dev/null
sudo systemctl restart haproxy &> /dev/null

set +e