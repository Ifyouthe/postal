#!/bin/bash
set -e

echo "==> Waiting for MariaDB..."
timeout=60
counter=0
until nc -z mariadb 3306 2>/dev/null; do
  counter=$((counter + 1))
  if [ $counter -gt $timeout ]; then
    echo "ERROR: MariaDB not available after ${timeout}s"
    exit 1
  fi
  sleep 1
done
echo "==> MariaDB is ready!"

echo "==> Initializing Postal database..."
postal initialize || echo "Database already initialized or error occurred"

echo "==> Starting Postal worker..."
postal worker &

echo "==> Starting Postal SMTP server..."
postal smtp-server &

echo "==> Starting Postal web server..."
exec postal web-server
