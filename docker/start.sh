#!/bin/bash
set -e

echo "==> Waiting for MariaDB at ${MAIN_DB_HOST}:${MAIN_DB_PORT}..."
timeout=90
counter=0

# Try multiple methods to check MariaDB availability
check_mariadb() {
  # Method 1: Try with nc if available
  if command -v nc &> /dev/null; then
    nc -z "${MAIN_DB_HOST}" "${MAIN_DB_PORT}" 2>/dev/null && return 0
  fi

  # Method 2: Try with bash /dev/tcp
  (echo > /dev/tcp/${MAIN_DB_HOST}/${MAIN_DB_PORT}) 2>/dev/null && return 0

  # Method 3: Try with ruby
  ruby -e "require 'socket'; TCPSocket.new('${MAIN_DB_HOST}', ${MAIN_DB_PORT}).close" 2>/dev/null && return 0

  return 1
}

until check_mariadb; do
  counter=$((counter + 1))
  if [ $counter -gt $timeout ]; then
    echo "ERROR: MariaDB not available after ${timeout}s"
    echo "Tried connecting to ${MAIN_DB_HOST}:${MAIN_DB_PORT}"
    exit 1
  fi
  echo "Waiting... ($counter/$timeout)"
  sleep 1
done
echo "==> MariaDB is ready!"

echo "==> Initializing Postal database..."
postal initialize || echo "Database already initialized"

echo "==> Starting Postal worker..."
postal worker &

echo "==> Starting Postal SMTP server..."
postal smtp-server &

echo "==> Starting Postal web server..."
exec postal web-server
