#!/bin/bash
# =============================================================================
# Configure control-node host proxy to nested HAProxy
# =============================================================================

set -euo pipefail

PROVIDER="${INFRA_PROVIDER:-libvirt}"

if [[ "${PROVIDER}" == "libvirt" ]]; then
  DEFAULT_CONTROL_IP="192.168.123.10"
  DEFAULT_HAPROXY_IP="192.168.123.20"
else
  DEFAULT_CONTROL_IP="192.168.57.10"
  DEFAULT_HAPROXY_IP="192.168.57.20"
fi

CONTROL_NODE_IP="${CONTROL_NODE_IP:-${DEFAULT_CONTROL_IP}}"
HAPROXY_IP="${HAPROXY_IP:-${DEFAULT_HAPROXY_IP}}"
PROXY_BIND_IP="${PROXY_BIND_IP:-0.0.0.0}"

echo "============================================"
echo "Configuring Host Proxy to Nested HAProxy"
echo "Provider: ${PROVIDER}"
echo "Control node listener IP: ${CONTROL_NODE_IP}"
echo "Nested HAProxy target IP: ${HAPROXY_IP}"
echo "Proxy bind IP: ${PROXY_BIND_IP}"
echo "============================================"

cat > /usr/local/bin/haproxy-host-proxy.sh <<EOF
#!/bin/bash
set -euo pipefail

HAPROXY_IP="${HAPROXY_IP}"
PROXY_BIND_IP="${PROXY_BIND_IP}"

cleanup() {
  jobs -p | xargs -r kill || true
}

trap cleanup EXIT INT TERM

# API via HAProxy frontend
socat TCP-LISTEN:80,bind=${PROXY_BIND_IP},fork,reuseaddr TCP:${HAPROXY_IP}:80 &

# HAProxy stats endpoint
socat TCP-LISTEN:8080,bind=${PROXY_BIND_IP},fork,reuseaddr TCP:${HAPROXY_IP}:8080 &

wait
EOF

chmod +x /usr/local/bin/haproxy-host-proxy.sh

cat > /etc/systemd/system/haproxy-host-proxy.service <<'EOF'
[Unit]
Description=Expose nested HAProxy endpoints on control-node
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/haproxy-host-proxy.sh
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable haproxy-host-proxy.service
systemctl restart haproxy-host-proxy.service

echo "Host proxy configured."
echo "Control-node API:   http://${CONTROL_NODE_IP}/api/users/"
echo "Control-node stats: http://${CONTROL_NODE_IP}:8080/stats"
echo "Host-local API:     http://127.0.0.1:18080/api/users/"
echo "Host-local stats:   http://127.0.0.1:18081/stats"
echo "============================================"