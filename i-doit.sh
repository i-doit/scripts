#!/bin/bash

export CONSOLE_BIN="/usr/local/bin/idoit"
export CONSOLE_CONFIG="/etc/i-doit/console.ini"
export APACHE_USER="www-data"
export SYSTEM_DATABASE="idoit_system"
export TENANT_DATABASE="idoit_data"
export TENANT_ID="1"
export MARIADB_USERNAME="idoit"
export MARIADB_PASSWORD=""
export MARIADB_HOSTNAME="localhost"
export INSTANCE_PATH="/var/www/html"
export BACKUP_DIR="/var/backups/i-doit"
# Max. age of backup files (in days):
export BACKUP_AGE=30
