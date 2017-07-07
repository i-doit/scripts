#!/bin/bash

##
## Install i-doit on a GNU/Linux operating system
##

##
## Copyright (C) 2017 synetics GmbH, <https://i-doit.com/>
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program. If not, see <http://www.gnu.org/licenses/>.
##

set -u

##
## Configuration
##

MARIADB_HOSTNAME="localhost"
MARIADB_SUPERUSER_PASSWORD="idoit"
MARIADB_INNODB_BUFFER_POOL_SIZE="1G"
APACHE_USER="www-data"
APACHE_GROUP="www-data"
IDOIT_ADMIN_CENTER_PASSWORD="admin"
MARIADB_USER_PASSWORD="idoit"
IDOIT_DEFAULT_TENANT="CMDB"
INSTALL_DIR="/var/www/html"
DATE=`date +%Y-m-d`
TMP_DIR="/tmp/i-doit_${DATE}"
UPDATE_FILE_PRO="https://i-doit.com/updates.xml"
UPDATE_FILE_OPEN="https://i-doit.org/updates.xml"
OS=""
BASENAME=`basename $0`
VERSION="0.1"

##--------------------------------------------------------------------------------------------------

function execute {
    log "Install i-doit on a GNU/Linux operating system"
    log ""
    log "Attention:"
    log "This script may cause serious damage to your operating system and all its data. It comes with absolutely no warrenty."
    log ""
    log "You may choose to automatically…"
    log "    1) install additional distribution packages,"
    log "    2) alter configuration of your PHP environment,"
    log "    3) alter configuration of your Apache Web server,"
    log "    4) alter configuration of your MariaDB DBMS, and"
    log "    5) download and install the latest version of i-doit pro or open"
    log ""

    askYesNo "Do you really want to use this script?"
    if [[ $? -gt 0 ]]; then
        log "Bye"
        exit 0
    fi

    log "\n--------------------------------------------------------------------------------\n"

    identifyOS

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the operating system?"
    if [[ $? -eq 0 ]]; then
        configureOS
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the PHP environment?"
    if [[ $? -eq 0 ]]; then
        configurePHP
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the Apache Web server?"
    if [[ $? -eq 0 ]]; then
        configureApache
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure MariaDB?"
    if [[ $? -eq 0 ]]; then
        configureMariaDB
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to prepare and install i-doit automatically?"
    if [[ $? -eq 0 ]]; then
        prepareIDoit
        installIDoit
    else
        log "Your operating system is prepared for the installation of i-doit."
        log "To complete the setup please follow the instructions as described in the i-doit Knowledge Base:"
        log "    https://kb.i-doit.com/display/en/Setup"
    fi
}

function identifyOS {
    if [[ -x "/usr/bin/lsb_release" ]]; then
        local os_id=`lsb_release --short --id`
        local os_codename=`lsb_release --short --codename`
        local os_description=`lsb_release --short --description`

        if [[ "$os_id" = "Debian" && "$os_codename" = "jessie" ]]; then
            log "Identified operating system as ${os_description}"
            log "Version 9 is recommended. Please consider to upgrade."
            OS="debian8"
        elif [[ "$os_id" = "Debian" && "$os_codename" = "stretch" ]]; then
            log "Identified operating system as ${os_description}"
            OS="debian9"
        elif [[ "$os_id" = "Ubuntu" && "$os_codename" = "xenial" ]]; then
            log "Identified operating system as ${os_description}"
            OS="ubuntu1604"
        else
            abort "Operating system ${os_description} is not supported"
        fi
    elif [[ -f "/etc/debian_version" ]]; then
        local os_release=`cat /etc/debian_version`
        local os_major_release=`cat /etc/debian_version | awk -F "." '{print $1}'`

        if [[ "$os_major_release" = "8" ]]; then
            log "Identified operating system as Debian GNU/Linux ${os_release} (jessie)"
            log "Version 9 is recommended. Please consider to upgrade."
            OS="debian8"
        elif [[ "$os_major_release" = "9" ]]; then
            log "Identified operating system as Debian GNU/Linux ${os_release} (stretch)"
            OS="debian9"
        else
            abort "Operating system Debian GNU/Linux ${os_release} is not supported"
        fi
    elif [[ -f "/etc/redhat-release" ]]; then
        local os_description=`cat /etc/redhat-release`

        abort "Operating system ${os_description} is not supported"
    elif [[ -f "/etc/SuSE-release" ]]; then
        local os_description=`cat /etc/SuSE-release | head -n1`

        abort "Operating system ${os_description} is not supported"
    else
        abort "Unable to identify operating system"
    fi
}

function configureOS {
    case "$OS" in
        "debian8")
            configureDebian8
            ;;
        "debian9")
            configureDebian9
            ;;
        "ubuntu1604")
            configureUbuntu1604
            ;;
        *)
            abort "Unkown operating system '${OS}'!?!"
    esac
}

function configureDebian8 {
    echo -n -e "Please enter a new password for MariaDB's super user 'root' [leave empty for '${MARIADB_SUPERUSER_PASSWORD}']: "

    read answer

    if [[ -n "$answer" ]]; then
      MARIADB_SUPERUSER_PASSWORD="$answer"
    fi

    log "Keep your Debian packages up-to-date"
    apt-get --quiet --yes update || abort "Unable to update Debian package repositories"
    apt-get --quiet --yes full-upgrade || abort "Unable to perform update of Debian packages"
    apt-get --quiet --yes clean || abort "Unable to cleanup Debian packages"
    apt-get --quiet --yes autoremove || abort "Unable to remove unnecessary Debian packages"

    log "Install required Debian packages"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password ${MARIADB_SUPERUSER_PASSWORD}" || abort "Unable to set MariaDB super user password"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password ${MARIADB_SUPERUSER_PASSWORD}" || abort "Unable to set MariaDB super user password"
    apt-get --quiet --yes install \
        apache2 libapache2-mod-php5 \
        php5 php5-cli php5-common php5-curl php5-gd php5-json php5-ldap php5-mcrypt php5-mysqlnd \
        php5-pgsql php5-memcached \
        mariadb-server mariadb-client \
        memcached unzip sudo || abort "Unable to install required Debian packages"
}

function configureDebian9 {
    log "Keep your Debian packages up-to-date"
    apt-get --quiet --yes update || abort "Unable to update Debian package repositories"
    apt-get --quiet --yes full-upgrade || abort "Unable to perform update of Debian packages"
    apt-get --quiet --yes clean || abort "Unable to cleanup Debian packages"
    apt-get --quiet --yes autoremove || abort "Unable to remove unnecessary Debian packages"

    log "Install required Debian packages"
    apt-get --quiet --yes install \
        apache2 libapache2-mod-php \
        mariadb-client mariadb-server \
        php php-bcmath php-cli php-common php-curl php-gd php-imagick php-json php-ldap php-mcrypt \
        php-memcached php-mysql php-pgsql php-xml php-zip \
        memcached unzip sudo || abort "Unable to install required Debian packages"
}

function configureUbuntu1604 {
    log "Keep your Ubuntu packages up-to-date"
    apt-get --quiet --yes update || abort "Unable to update Ubuntu package repositories"
    apt-get --quiet --yes full-upgrade || abort "Unable to perform update of Ubuntu packages"
    apt-get --quiet --yes clean || abort "Unable to cleanup Ubuntu packages"
    apt-get --quiet --yes autoremove || abort "Unable to remove unnecessary Ubuntu packages"

    log "Install required Ubuntu packages"
    apt-get --quiet --yes install \
        apache2 libapache2-mod-php \
        mariadb-client mariadb-server \
        php php-bcmath php-cli php-common php-curl php-gd php-imagick php-json php-ldap php-mcrypt \
        php-memcached php-mysql php-pgsql php-xml php-zip \
        memcached unzip || abort "Unable to install required Ubuntu packages"
}

function configurePHP {
    log "Configure PHP"

    local ini_file=""
    local php_en_mod=""
    local php_version=`php --version | head -n1 -c7 | tail -c3`

    if [[ "$php_version" = "7.0" ]]; then
        ini_file="/etc/php/7.0/mods-available/i-doit.ini"
        php_en_mod=`which phpenmod`
    elif [[ "$php_version" = "5.6" ]]; then
        log "PHP 5.6 is installed, but 7.0 is recommended. Please consider to upgrade."
        ini_file="/etc/php5/mods-available/i-doit.ini"
        php_en_mod=`which php5enmod`
    elif [[ "$php_version" = "5.5" || "$php_version" = "5.4" ]]; then
        log "PHP ${php_version} is way too old. Please upgrade."
        ini_file="/etc/php5/mods-available/i-doit.ini"
        php_en_mod=`which php5enmod`
    else
        abort "PHP ${php_version} is not supported. Please upgrade/downgrade."
    fi

    cat > "$ini_file" << EOF
allow_url_fopen = Yes
file_uploads = On
magic_quotes_gpc = Off
max_execution_time = 300
max_file_uploads = 42
max_input_time = 60
max_input_vars = 10000
memory_limit = 256M
post_max_size = 128M
register_argc_argv = On
register_globals = Off
short_open_tag = On
upload_max_filesize = 128M
display_errors = Off
display_startup_errors = Off
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
log_errors = On
default_charset = "UTF-8"
default_socket_timeout = 60
date.timezone = Europe/Berlin
session.gc_maxlifetime = 604800
session.cookie_lifetime = 0
mysqli.default_socket = /var/run/mysqld/mysqld.sock
EOF

   log "Enable PHP settings"
   "$php_en_mod" i-doit
   log "Enable PHP module for memcached"
   "$php_en_mod" memcached
}

function configureApache {
    log "Configure Apache Web server"

    local a2_en_site=`which a2ensite`
    local a2_dis_site=`which a2dissite`
    local a2_en_mod=`which a2enmod`

   cat > /etc/apache2/sites-available/i-doit.conf << EOF
<VirtualHost *:80>
        ServerAdmin i-doit@example.net

        DocumentRoot ${INSTALL_DIR}/
        <Directory ${INSTALL_DIR}/>
                # See ${INSTALL_DIR}/.htaccess for details
                AllowOverride All
                Require all granted
        </Directory>

        LogLevel warn
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

   log "Disable default VHost"
   "$a2_dis_site" 000-default || abort "Unable to disable default VHost"
   log "Cleanup VHost directory"
   rm -rf "${INSTALL_DIR}"/* || abort "Unable to remove files"
   log "Change directory ownership"
   chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || abort "Unable to change ownership"
   log "Enable new VHost settings"
   "$a2_en_site" i-doit || abort "Unable to enable VHost settings"
   log "Enable Apache module rewrite"
   "$a2_en_mod" rewrite || abort "Unable to enable Apache module rewrite"
   log "Restart Apache Web server"
   systemctl restart apache2.service || abort "Unable to restart Apache Web server"
}

function configureMariaDB {
    log "Configure MariaDB DBMS"

    local mysql_bin=`which mysql`

    local mariadb_config=""

    case "$OS" in
        "debian8")
            mariadb_config="/etc/mysql/conf.d/i-doit.cnf"
            ;;
        "debian9"|"ubuntu1604")
            echo -n -e \
                "Please enter a new password for MariaDB's super user 'root' [leave empty for '${MARIADB_SUPERUSER_PASSWORD}']: "

            read answer

            if [[ -n "$answer" ]]; then
                MARIADB_SUPERUSER_PASSWORD="$answer"
            fi

            log "Set root password"
            "$mysql_bin" -uroot \
                -e"UPDATE mysql.user SET Password=PASSWORD('${MARIADB_SUPERUSER_PASSWORD}') WHERE User='root';" || \
                abort "Unable to set root password"
            log "Allow root login only from localhost"
            "$mysql_bin" -uroot \
                -e"DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" || \
                abort "Unable to disallow remote login for root"
            log "Remove anonymous user"
            "$mysql_bin" -uroot \
                -e"DELETE FROM mysql.user WHERE User='';" || \
                abort "Unable to remove anonymous user"
            log "Remove test database"
            "$mysql_bin" -uroot \
                -e"DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';" || \
                abort "Unable to remove test database"
            log "Allow to login user 'root' with password for MariaDB"
            "$mysql_bin" -uroot \
                -e"UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';" || \
                abort "Unable to update user table"
            "$mysql_bin" -uroot \
                -e"FLUSH PRIVILEGES;" || \
                abort "Unable to flush privileges"

            mariadb_config="/etc/mysql/mariadb.conf.d/99-i-doit.cnf"
            ;;
        *)
            abort "Unkown operating system '${OS}'!?!"
    esac

    log "Prepare shutdown of MariaDB"
    "$mysql_bin" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" -e"SET GLOBAL innodb_fast_shutdown = 0" || \
      abort "Unable to prepare shutdown"
    log "Stop MariaDB"
    systemctl stop mysql.service || abort "Unable to stop MariaDB"
    log "Move old MariaDB log files"
    mv /var/lib/mysql/ib_logfile[01] /tmp || abort "Unable to move old log files"

    log "How many bytes of your RAM do you like to spend to MariaDB?"
    echo -n -e "You SHOULD give MariaDB ~ 50 per cent of your RAM [leave empty for '${MARIADB_INNODB_BUFFER_POOL_SIZE}']: "

    read answer

    if [[ -n "$answer" ]]; then
        MARIADB_INNODB_BUFFER_POOL_SIZE="$answer"
    fi

    log "Configure MariaDB settings"
    cat > "$mariadb_config" << EOF
[mysqld]

# This is the number 1 setting to look at for any performance optimization
# It is where the data and indexes are cached: having it as large as possible will
# ensure MySQL uses memory and not disks for most read operations.
#
# Typical values are 1G (1-2GB RAM), 5-6G (8GB RAM), 20-25G (32GB RAM), 100-120G (128GB RAM).
innodb_buffer_pool_size = ${MARIADB_INNODB_BUFFER_POOL_SIZE}

# Use multiple instances if you have innodb_buffer_pool_size > 10G, 1 every 4GB
innodb_buffer_pool_instances = 1

# Redo log file size, the higher the better.
# MySQL/MariaDB writes two of these log files in a default installation.
innodb_log_file_size = 512M

innodb_sort_buffer_size = 64M
sort_buffer_size = 262144 # default
join_buffer_size = 262144 # default

max_allowed_packet = 128M
max_heap_table_size = 16M
query_cache_min_res_unit = 4096
query_cache_type = 1
query_cache_limit = 5M
query_cache_size = 80M

tmp_table_size = 32M
max_connections = 200
innodb_file_per_table = 1

# Disable this (= 0) if you have only one to two CPU cores, change it to 4 for a quad core.
innodb_thread_concurrency = 0

# Disable this (= 0) if you have slow harddisks
innodb_flush_log_at_trx_commit = 1
innodb_flush_method = O_DIRECT

innodb_lru_scan_depth = 2048
table_definition_cache = 1024
table_open_cache = 2048
# Only if your have MySQL 5.6 or higher, do not use with MariaDB!
#table_open_cache_instances = 4

sql-mode = ""
EOF

    log "Start MariaDB"
    systemctl start mysql.service || abort "Unable to start MariaDB"
}

function prepareIDoit {
    log "Prepare i-doit"

    if [[ ! -f "${INSTALL_DIR}/i-doit.zip" ]]; then
        echo -n -e "Which variant of i-doit do you like to install? [PRO|open]: "

        local update_file_url=""

        read variant

        case "$variant" in
            ""|"PRO"|"Pro"|"pro")
                update_file_url="$UPDATE_FILE_PRO"
                ;;
            "OPEN"|"Open"|"open")
                update_file_url="$UPDATE_FILE_OPEN"
                ;;
            *)
                abort "Unknown variant"
        esac

        log "Identify latest version of i-doit"
        wget --quiet -O "$TMP_DIR/updates.xml" "$update_file_url" || \
            abort "Unable to fetch file from '${update_file_url}'"

        local url=`cat "${TMP_DIR}/updates.xml" | tail -n5 | head -n1 | sed "s/<filename>//" | sed "s/<\/filename>//" | sed "s/-update.zip/.zip/" | awk '{print $1}'`

        test -n "$url" || abort "Missing URL"

        wget  --quiet -O "${INSTALL_DIR}/i-doit.zip" "$url" || abort "Unable to download file"
    fi

    log "Unzip package"
    cd "$INSTALL_DIR"
    unzip -q i-doit.zip || abort "Unable to unzip file"

    log "Prepare files and directories"
    mv i-doit.zip "$TMP_DIR" || abort "Unable to remove downloaded file"
    chown "$APACHE_USER":"$APACHE_GROUP" -R . || abort "Unable to change ownership"
    find . -type d -name \* -exec chmod 775 {} \; || "Unable to change directory permissions"
    find . -type f -exec chmod 664 {} \; || "Unable to change file permissions"
    chmod 774 controller tenants import updatecheck *.sh setup/*.sh || "Unable to change executable permissions"
}

function installIDoit {
    log "Install i-doit"

    echo -e -n "Please enter the MariaDB hostname [leave empty for '${MARIADB_HOSTNAME}']: "
    read answer
    if [[ -n "$answer" ]]; then
        MARIADB_HOSTNAME="$answer"
    fi

    echo -e -n "Please enter the password for the new MariaDB user [leave empty for '${MARIADB_USER_PASSWORD}']: "
    read answer
    if [[ -n "$answer" ]]; then
        MARIADB_USER_PASSWORD="$answer"
    fi

    echo -e -n "Please enter the password for the i-doit Admin Center [leave empty for '${IDOIT_ADMIN_CENTER_PASSWORD}']: "
    read answer
    if [[ -n "$answer" ]]; then
        IDOIT_ADMIN_CENTER_PASSWORD="$answer"
    fi

    echo -e -n "Please enter the name of the first tenant [leave empty for '${IDOIT_DEFAULT_TENANT}']: "
    read answer
    if [[ -n "$answer" ]]; then
        IDOIT_DEFAULT_TENANT="$answer"
    fi

    cd "${INSTALL_DIR}/setup"

    ./install.sh -n "$IDOIT_DEFAULT_TENANT" \
       -s "idoit_system" -m "idoit_data" -h "$MARIADB_HOSTNAME" -p "$MARIADB_USER_PASSWORD" \
       -a "$IDOIT_ADMIN_CENTER_PASSWORD" -q || abort "i-doit setup script returned an error"

    local ipaddress=$(hostname -I |tr -d '[:space:]')
    log "Your setup is ready. Navigate to http://${ipaddress}/ with your Web browser"
    log "and login with username/password 'admin'"
}

function setup {
    test `whoami` = "root" || abort "Superuser rights required"

    mkdir -p "$TMP_DIR" || abort "Unable to create temporary directory"
}

function tearDown {
    test -d "$TMP_DIR" && log "Cleanup" && ( rm -rf "$TMP_DIR" || echo "Failed" 1>&2 )
}

function showUsage {
    log "Usage: $BASENAME [OPTIONS]"
    log ""
    log "Options:"
    log "    -h, --help      Print usage"
    log "    -v, --version   Print version"
}

function showVersion {
    log "$BASENAME $VERSION"
}

function log {
    echo -e "$1"
}

function askYesNo {
    echo -n -e "$1 [Y]es [n]o: "

    read answer

    case "$answer" in
        ""|"Y"|"Yes"|"y"|"yes")
            return 0
            ;;
        "No"|"no"|"n"|"N")
            return 1
            ;;
        *)
            log "Sorry, what do you mean?"
            prntPrompt "$1"
    esac
}

function finish {
    tearDown
    log "Done. Have fun :-)"
    exit 0
}

function abort {
    echo -e "$1"  1>&2
    tearDown
    echo "Operation failed. Please check what is wrong and try again." 1>&2
    exit 1
}

##--------------------------------------------------------------------------------------------------

ARGS=`getopt \
    -o vh \
    --long help,version -- "$@" 2> /dev/null`

eval set -- "$ARGS"

while true ; do
    case "$1" in
        -h|--help)
            showUsage
            exit 0
            ;;
        -v|--version)
            showVersion
            exit 0
            ;;
        --)
            shift;
            break;;
        *)
            log "Unkown option '${1}'."
            printUsage
            exit 1;;
    esac
done

setup && execute && finish
