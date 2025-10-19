#!/usr/bin/env python3
import logging
import os
import time
import random

# --- Dummy RDS credentials ---
RDS_HOST = "dummy-db-instance.cluster-abcdefg123.us-east-1.rds.amazonaws.com"
RDS_PORT = 3306
RDS_USER = "appuser"
RDS_DB   = "production_db"

# --- Log file setup ---
log_dir = "/var/log/python-app"
os.makedirs(log_dir, exist_ok=True)
log_file = f"{log_dir}/app.log"

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

logging.info("Starting simulated RDS connection test...")

# --- Run for 5 attempts ---
for attempt in range(1, 6):
    logging.info(f"[Attempt {attempt}] Attempting to connect to RDS: host={RDS_HOST} port={RDS_PORT} user={RDS_USER} db={RDS_DB}")

    # Simulate network delay
    time.sleep(2)

    # Randomly succeed or fail
    if random.choice([True, False]):
        logging.info(f"[Attempt {attempt}] Connected to RDS ({RDS_HOST}:{RDS_PORT}) successfully.")
    else:
        # Simulate 30-second timeout error
        logging.error(f"[Attempt {attempt}] Failed to connect to RDS ({RDS_HOST}:{RDS_PORT}) for user {RDS_USER}: Connection timed out after 30 seconds.")

    # Wait a bit before next attempt
    time.sleep(2)

logging.info("Simulated RDS connection test completed.")