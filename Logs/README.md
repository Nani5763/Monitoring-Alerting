### Process ####

**Steps:**
Installing Loki
Installation Steps
wget https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip
unzip -o loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki


**Downloads the Loki binary:**

Makes it executable and moves it to /usr/local/bin so it can run anywhere.

sudo mkdir -p /etc/loki /var/lib/loki/index /var/lib/loki/chunks /var/lib/loki/wal
sudo useradd --system --no-create-home --shell /bin/false loki || true
sudo chown -R loki:loki /var/lib/loki


**Creates directories:**

/etc/loki → config file

/var/lib/loki/index → BoltDB index files (metadata for logs)

/var/lib/loki/chunks → actual log data

/var/lib/loki/wal → write-ahead logs for durability

Creates a system user loki to run Loki securely.

Loki Configuration (/etc/loki-config.yaml)
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  max_chunk_age: 1h

schema_config:
  configs:
    - from: 2025-09-23
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /var/lib/loki/index
  filesystem:
    directory: /var/lib/loki/chunks

limits_config:
  allow_structured_metadata: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

### Explanation of key sections:

auth_enabled: false

Disables authentication (any client can push/query logs).

server

http_listen_port: 3100 → Loki listens for HTTP requests (from Promtail or Grafana).

ingester

Buffers logs in memory before writing to chunks.

lifecycler + ring → manages log stream ownership (important for clustering).

chunk_idle_period: 5m → close chunk if idle 5 minutes.

max_chunk_age: 1h → force flush chunk after 1 hour.

schema_config

### Defines how logs are stored and indexed:

from: 2025-09-23 → schema applies to logs on/after this date.

store: boltdb → metadata stored in BoltDB.

object_store: filesystem → actual logs stored as files.

index.period: 24h → create a new index file every day.

storage_config

BoltDB → /var/lib/loki/index (index/metadata)

Filesystem → /var/lib/loki/chunks (actual logs)

limits_config

Reject old logs > 7 days (168h).

Disable structured metadata.

Systemd Service for Loki
[Unit]
Description=Loki Log Aggregation System
After=network.target

[Service]
ExecStart=/usr/local/bin/loki --config.file=/etc/loki-config.yaml
Restart=always
User=loki
Group=loki
WorkingDirectory=/var/lib/loki

[Install]
WantedBy=multi-user.target


Runs Loki as a service (systemctl start loki)

Restarts automatically if it fails

Runs as the loki user for security

### Installing Promtail ###
* Installation Steps
wget https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip -o promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
* sudo chmod +x /usr/local/bin/promtail
sudo mkdir -p /etc/promtail

* Downloads Promtail binary, makes it executable, and moves it to /usr/local/bin.

* Creates /etc/promtail for config files.

* Promtail Configuration (/etc/promtail/config.yaml)
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: python-app
    static_configs:
      - targets:
          - localhost
        labels:
          job: python-app
          host: ${HOSTNAME}
          __path__: /var/log/python-app/*.log

### Explanation of key sections

server

Port 9080 → Promtail’s HTTP server (status/metrics)

positions

/tmp/positions.yaml → tracks last read line in each log file

Ensures Promtail doesn’t resend old logs

clients

Loki endpoint: http://localhost:3100/loki/api/v1/push

Promtail pushes logs to Loki here

scrape_configs

### Defines what logs to read and label

### Example:

* __path__: /var/log/python-app/*.log
job: python-app
host: ${HOSTNAME}


* Promtail reads all .log files in /var/log/python-app/, adds labels, and sends them to Loki

* Systemd Service for Promtail
[Unit]
Description=Promtail service
After=network.target

* [Service]
ExecStart=/usr/local/bin/promtail --config.file=/etc/promtail/config.yaml
Restart=always
User=root

* [Install]
WantedBy=multi-user.target


* Promtail runs as root (needed to read system logs)

* Auto-restarts on failure

### How Loki + Promtail Work Together ####
### Work Flow

* Promtail watches log files on your system (/var/log/...)

* Adds labels to each log line (job, host, etc.)

* Pushes logs to Loki’s HTTP API (localhost:3100)

* Loki ingester receives logs → buffers in memory → writes chunks to disk

* Metadata (labels → chunk mapping) stored in BoltDB index

* Grafana queries Loki → fetches logs from chunks using index