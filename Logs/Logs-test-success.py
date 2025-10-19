import logging
import os
import time
import random

# Log directory
log_dir = "/var/log/python-app"
os.makedirs(log_dir, exist_ok=True)
log_file = f"{log_dir}/app.log"

# Logging setup
logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

logging.info("Starting random number log generator...")

# Generate 20 random numbers
for i in range(1, 21):
    number = random.randint(1, 100)
    if number % 2 == 0:
        logging.info(f"[{i}] Random number: {number} (success)")
    else:
        logging.error(f"[{i}] Random number: {number} (error)")
    time.sleep(1)  # 1 second delay between logs

logging.info("Random number log generation completed.")