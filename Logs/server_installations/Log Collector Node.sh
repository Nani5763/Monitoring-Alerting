#!/bin/bash
set -e

########################################
# 🧱 SYSTEM UPDATE
########################################
echo "=== Updating system and installing prerequisites ==="
sudo apt update && sudo apt install -y wget unzip curl

########################################
# 📦 INSTALL PROMTAIL
########################################
echo "=== Installing Promtail ==="
cd /tmp
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip -o promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail
sudo mkdir -p /etc/promtail
sudo mkdir -p /var/log/python-app

########################################
# ⚙️ PROMTAIL CONFIGURATION
########################################
# ⚠️ Replace <EC2-1-Private-IP> with your Loki server's PRIVATE IP (not public)
cat <<EOF | sudo tee /etc/promtail/config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://172.31.17.229:3100/loki/api/v1/push

scrape_configs:
  # Systemd logs
  - job_name: systemd-journal
    journal:
      path: /var/log/journal
      labels:
        job: systemd
        host: \${HOSTNAME}
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'

  # Apache2 access logs
  - job_name: apache2
    static_configs:
      - targets:
          - localhost
        labels:
          job: apache2-access
          host: \${HOSTNAME}
          __path__: /var/log/apache2/access.log

  # Apache2 error logs
  - job_name: varerror
    static_configs:
      - targets:
          - localhost
        labels:
          job: apache2-error
          host: \${HOSTNAME}
          __path__: /var/log/apache2/error.log

  # Python application logs
  - job_name: python-app
    static_configs:
      - targets:
          - localhost
        labels:
          job: python-app
          host: \${HOSTNAME}
          __path__: /var/log/python-app/*.log
EOF

########################################
# 🧩 CREATE SYSTEMD SERVICE
########################################
cat <<EOF | sudo tee /etc/systemd/system/promtail.service
[Unit]
Description=Promtail service
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail --config.file=/etc/promtail/config.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

########################################
# 🚀 START & ENABLE PROMTAIL
########################################
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
sudo systemctl status promtail --no-pager

########################################
# ✅ COMPLETION MESSAGE
########################################
echo "=================================================="
echo "✅ Promtail installed and configured!"
echo "Sending logs to: http://<EC2-1-Private-IP>:3100"
echo "Logs collected:"
echo "  • Systemd journal"
echo "  • Apache2 access/error logs"
echo "  • Python app logs (/var/log/python-app/*.log)"
echo "=================================================="
