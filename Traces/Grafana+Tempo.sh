#!/bin/bash
set -e

########################################
# 🧱 SYSTEM UPDATE & PREREQUISITES
########################################
echo "=== Updating system and installing prerequisites ==="
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y software-properties-common unzip wget curl gnupg

########################################
# ⏱ INSTALL TEMPO
########################################
echo "=== Installing Tempo ==="
cd /tmp
wget https://github.com/grafana/tempo/releases/download/v2.8.2/tempo_2.8.2_linux_amd64.tar.gz
tar -xvf tempo_2.8.2_linux_amd64.tar.gz
sudo mv tempo /usr/local/bin/
sudo chmod +x /usr/local/bin/tempo
sudo mkdir -p /etc/tempo /var/lib/tempo

# Tempo config
cat <<EOF | sudo tee /etc/tempo/config.yaml
server:
  http_listen_port: 3200
  grpc_listen_port: 9096

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

ingester:
  trace_idle_period: 10s
  max_block_duration: 5m

compactor:
  compaction:
    block_retention: 1h

storage:
  trace:
    backend: local
    local:
      path: /var/lib/tempo/traces
EOF

# Tempo service
cat <<EOF | sudo tee /etc/systemd/system/tempo.service
[Unit]
Description=Grafana Tempo service
After=network.target

[Service]
ExecStart=/usr/local/bin/tempo --config.file=/etc/tempo/config.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tempo
sudo systemctl start tempo
sudo systemctl status tempo --no-pager

########################################
# ✅ COMPLETION MESSAGE
########################################
echo "=================================================="
echo "✅ Installation complete!"
echo "Grafana running on: http://<your-server-ip>:3000"
echo "Tempo listening on: http://localhost:3200"
echo "=================================================="