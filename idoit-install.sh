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
## You **should not** edit this config. You will be asked for your preferred settings.
##

MARIADB_HOSTNAME="localhost"
MARIADB_SUPERUSER_PASSWORD="idoit"
MARIADB_INNODB_BUFFER_POOL_SIZE="1G"
APACHE_USER="www-data"
APACHE_GROUP="www-data"
IDOIT_ADMIN_CENTER_PASSWORD="admin"
#MARIADB_USER_PASSWORD="idoit"
IDOIT_DEFAULT_TENANT="CMDB"
INSTALL_DIR="/var/www/html"
DATE=`date +%Y-m-d`
TMP_DIR="/tmp/i-doit_${DATE}"
UPDATE_FILE_PRO="https://i-doit.com/updates.xml"
UPDATE_FILE_OPEN="https://i-doit.org/updates.xml"
OS=""
SCRIPT_SETTINGS="/etc/i-doit/i-doit.sh"
CONTROLLER_BIN="/usr/local/bin/idoit"
JOBS_BIN="/usr/local/bin/idoit-jobs"
CRON_FILE="/etc/cron.d/i-doit"
BASENAME=`basename $0`
VERSION="0.4"

WGET_BIN=`which wget`

##--------------------------------------------------------------------------------------------------

function execute {
    log "Install i-doit on a GNU/Linux operating system"
    log ""
    log "Attention:"
    log "This script alters your OS. It will install new packages and will change configuration settings."
    log "Only use it on a fresh installation of a GNU/Linux OS."
    log "It comes with absolutely no warrenty."
    log "Read the documentation carefully before you continue:"
    log ""
    log "    https://github.com/bheisig/i-doit-scripts"
    log ""
    log "This script will automatically…"
    log ""
    log "    1) install additional distribution packages,"
    log "    2) alter configuration of your PHP environment,"
    log "    3) alter configuration of your Apache Web server,"
    log "    4) alter configuration of your MariaDB DBMS, and"
    log "    5) download and install the latest version of i-doit pro or open"
    log "    6) deploy cron jobs and an easy-to-use CLI tool for your i-doit instance"
    log ""
    log "You may skip any step if you like."
    log ""

    askYesNo "Do you really want to continue?"
    if [[ "$?" -gt 0 ]]; then
        log "Bye"
        exit 0
    fi

    log "\n--------------------------------------------------------------------------------\n"

    identifyOS

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the operating system?"
    if [[ "$?" -eq 0 ]]; then
        configureOS
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the PHP environment?"
    if [[ "$?" -eq 0 ]]; then
        configurePHP
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure the Apache Web server?"
    if [[ "$?" -eq 0 ]]; then
        configureApache
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure MariaDB?"
    if [[ "$?" -eq 0 ]]; then
        configureMariaDB
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to prepare and install i-doit automatically?"
    if [[ "$?" -eq 0 ]]; then
        prepareIDoit
        installIDoit

        local ipaddress=$(hostname -I |tr -d '[:space:]')
        log "Your setup is ready. Navigate to"
        log ""
        log "    http://${ipaddress}/"
        log ""
        log "with your Web browser and login with username/password 'admin'"
    else
        log "Your operating system is prepared for the installation of i-doit."
        log "To complete the setup please follow the instructions as described in the i-doit Knowledge Base:"
        log ""
        log "    https://kb.i-doit.com/display/en/Setup"
    fi

    log "\n--------------------------------------------------------------------------------\n"

    askYesNo "Do you want to configure i-doit cron jobs?"
    if [[ "$?" -eq 0 ]]; then
        deployScriptSettings
        deployController
        deployJobScript
        deployCronJobs

        log "Cron jobs are successfully activated. To change the execution date and time please edit this file:"
        log ""
        log "    $CRON_FILE"
        log ""
        log "There is also a script available for all system users to execute the i-doit controller command line tool:"
        log ""
        log "    idoit"
        log ""
        log "The needed cron jobs are defined here:"
        log ""
        log "    $JOBS_BIN"
        log ""
        log "If needed you can change the settings of both the i-doit controller and the cron jobs:"
        log ""
        log "    $SCRIPT_SETTINGS"
    fi

    case "$OS" in
        "ubuntu1604"|"ubuntu1610"|"ubuntu1704")
            log "To garantee that all your changes take effect you should restart your system."

            askYesNo "Do you want to restart your system NOW?"
            if [[ "$?" -eq 0 ]]; then
                systemctl reboot
            fi
            ;;
    esac
}

function identifyOS {
    if [[ -x "/usr/bin/lsb_release" ]]; then
        local os_id=`lsb_release --short --id`
        local os_codename=`lsb_release --short --codename`
        local os_description=`lsb_release --short --description`

        if [[ "$os_id" = "Debian" && "$os_codename" = "jessie" ]]; then
            log "Operating system identified as ${os_description}"
            log "Version 9 is recommended. Please consider to upgrade."
            OS="debian8"
        elif [[ "$os_id" = "Debian" && "$os_codename" = "stretch" ]]; then
            log "Operating system identified as ${os_description}"
            OS="debian9"
        elif [[ "$os_id" = "Ubuntu" && "$os_codename" = "xenial" ]]; then
            log "Operating system identified as ${os_description}"
            OS="ubuntu1604"
        elif [[ "$os_id" = "Ubuntu" && "$os_codename" = "yakkety" ]]; then
            log "Operating system identified as ${os_description}"
            OS="ubuntu1610"
        elif [[ "$os_id" = "Ubuntu" && "$os_codename" = "zesty" ]]; then
            log "Operating system identified as ${os_description}"
            OS="ubuntu1704"
        else
            abort "Operating system ${os_description} is not supported"
        fi
    elif [[ -f "/etc/debian_version" ]]; then
        local os_release=`cat /etc/debian_version`
        local os_major_release=`cat /etc/debian_version | awk -F "." '{print $1}'`

        if [[ "$os_major_release" = "8" ]]; then
            log "Operating system identified as Debian GNU/Linux ${os_release} (jessie)"
            log "Version 9 is recommended. Please consider to upgrade."
            OS="debian8"
        elif [[ "$os_major_release" = "9" ]]; then
            log "Operating system identified as Debian GNU/Linux ${os_release} (stretch)"
            OS="debian9"
        else
            abort "Operating system Debian GNU/Linux ${os_release} is not supported"
        fi
    elif [[ -f "/etc/centos-release" ]]; then
        local os_description=`cat /etc/centos-release`
        local os_release=`cat /etc/centos-release | grep -o '[0-9]\.[0-9]'`

        if [[ "$os_release" = "7.3" ]]; then
            log "Operating system identified as CentOS ${os_release}"
            OS="centos73"
        else
            abort "Operating system CentOS $os_release is not supported"
        fi

        APACHE_USER="apache"
        APACHE_GROUP="apache"
    elif [[ -f "/etc/redhat-release" ]]; then
        local os_description=`cat /etc/redhat-release`
        local os_release=`cat /etc/redhat-release | grep -o '[0-9]\.[0-9]'`

        if [[ "$os_release" = "7.3" ]]; then
            log "Operating system identified as Red Hat Enterprise Linux (RHEL) ${os_release}"
            OS="redhat73"
        else
            abort "Operating system Red Hat Enterprise Linux (RHEL) $os_release is not supported"
        fi

        APACHE_USER="apache"
        APACHE_GROUP="apache"
    elif [[ -f "/etc/SuSE-release" ]]; then
        local os_description=`cat /etc/SuSE-release | head -n1`

        abort "Operating system ${os_description} is not supported"
    else
        abort "Unable to identify operating system"
    fi

    local arch=`uname -m`

    if [[ "$arch" != "x86_64" ]]; then
        log "Attention! The system architecture is not x86 64 bit, but ${arch}. This could cause unwanted behaviour."
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
        "ubuntu1604"|"ubuntu1610"|"ubuntu1704")
            configureUbuntu1604
            ;;
        "redhat73"|"centos73")
            configureRedHat73
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
    debconf-set-selections <<< \
        "mariadb-server-10.0 mysql-server/root_password password ${MARIADB_SUPERUSER_PASSWORD}" || \
        abort "Unable to set MariaDB super user password"
    debconf-set-selections <<< \
        "mariadb-server-10.0 mysql-server/root_password_again password ${MARIADB_SUPERUSER_PASSWORD}" || \
        abort "Unable to set MariaDB super user password"
    apt-get --quiet --yes install \
        apache2 libapache2-mod-php5 \
        php5 php5-cli php5-common php5-curl php5-gd php5-json php5-ldap php5-mcrypt php5-mysqlnd \
        php5-pgsql php5-memcached \
        mariadb-server mariadb-client \
        memcached unzip sudo moreutils || abort "Unable to install required Debian packages"
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
        memcached unzip sudo moreutils || abort "Unable to install required Debian packages"
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
        memcached unzip moreutils || abort "Unable to install required Ubuntu packages"
}

function configureRedHat73 {
    local os_description=""
    local mariadb_url=""

    case "$OS" in
        "redhat73")
            os_description="Red Hat Enterprise Linux (RHEL)"
            mariadb_url="http://yum.mariadb.org/10.1/rhel7-amd64"
            ;;
        "centos73")
            os_description="CentOS"
            mariadb_url="http://yum.mariadb.org/10.1/centos7-amd64"
            ;;
    esac

    log "Keep you yum packages up-to-date"
    yum --assumeyes --quiet update
    yum --assumeyes --quiet autoremove
    yum --assumeyes --quiet clean all

    log "Install some important packages, for example Apache Web server"
    yum --assumeyes --quiet install httpd unzip zip wget moreutils

    log "$os_description 7.3 has out-dated packages for PHP and MariaDB. This script will fix this issue by enabling these 3rd party repositories:"
    log ""
    log "    Webtatic.com for PHP 7.0"
    log "    Official MariaDB repository for MariaDB 10.1"
    log ""

    askYesNo "Do you agree with it?"
    if [[ "$?" -eq 1 ]]; then
        abort "Requirements for i-doit not met"
    fi

    log "Enable Webtatic repository"
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || \
        abort "Unable to install EPEL"
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm || \
        abort "Unable to enable Webtatic"

    log "Install PHP packages"
    yum --assumeyes --quiet install \
        php70w php70w-bcmath php70w-cli php70w-common php70w-gd php70w-ldap php70w-mbstring \
        php70w-mcrypt php70w-mysqlnd php70w-opcache php70w-pdo php70w-pecl-imagick \
        php70w-pecl-memcached php70w-pgsql php70w-soap php70w-xml || \
        abort "Unable to install PHP packages"

    log "Enable MariaDB repository"
    cat > /etc/yum.repos.d/MariaDB.repo << EOF
# MariaDB 10.1 repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = $mariadb_url
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

    if [[ "$?" -gt 0 ]]; then
        abort "Unable to create and edit file '/etc/yum.repos.d/MariaDB.repo'"
    fi

    log "Install MariaDB packages"
    yum --assumeyes --quiet install MariaDB-server MariaDB-client || \
        abort "Unable to install MariaDB"

    log "Enable services"
    systemctl enable httpd.service || abort "Cannot enable Apache Web server"
    systemctl enable mariadb.service || abort "Cannot enable MariaDB server"

    log "Start services"
    systemctl start httpd.service || abort "Unable to start Apache Web server"
    systemctl start mariadb.service || abort "Unable to start MariaDB server"

    log "Allow incoming HTTP traffic"
    firewall-cmd --permanent --add-service=http || abort "Unable to configure firewall"
    systemctl restart firewalld.service || abort "Unable to restart firewall"
}

function configureSUSE12SP2 {
    zypper refresh
    zypper update
    zypper install apache2 mariadb mariadb-client moreutils
    zypper clean
}

function configurePHP {
    log "Configure PHP"

    local ini_file=""
    local php_en_mod=""
    local php_version=`php --version | head -n1 -c7 | tail -c3`

    if [[ "$OS" = "redhat73" || "$OS" = "centos73" ]]; then
        ini_file="/etc/php.d/i-doit.ini"
    elif [[ "$php_version" = "7.0" ]]; then
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

    log "Write PHP settings to '${ini_file}'"
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
EOF

    if [[ "$?" -gt 0 ]]; then
        abort "Unable to create and edit file '${ini_file}'"
    fi

    log "Append path to MariaDB UNIX socket to PHP settings"
    case "$OS" in
        "redhat73"|"centos73")
            echo "mysqli.default_socket = /var/lib/mysql/mysql.sock" >> "$ini_file" || \
                abort "Unable to alter PHP settings"
            ;;
        *)
            echo "mysqli.default_socket = /var/run/mysqld/mysqld.sock" >> "$ini_file" || \
                abort "Unable to alter PHP settings"
            ;;
    esac

    if [[ -n "$php_en_mod" ]]; then
        log "Enable PHP settings"
        "$php_en_mod" i-doit
        log "Enable PHP module for memcached"
        "$php_en_mod" memcached
    fi
}

function configureApache {
    log "Configure Apache Web server"

    case "$OS" in
        "redhat73"|"centos73")
            # TODO FIXME
            cat > /etc/httpd/conf.d/i-doit.conf << EOF
<Directory /var/www/html/>
        AllowOverride All
</Directory>
EOF

            if [[ "$?" -gt 0 ]]; then
                abort "Unable to create and edit file '/etc/httpd/conf.d/i-doit.conf'"
            fi

            test ! -d "$INSTALL_DIR" && (
                    mkdir -p "$INSTALL_DIR" || \
                        abort "Unable to create directory '${INSTALL_DIR}'"
            )

            log "Cleanup VHost directory"
            rm -rf "${INSTALL_DIR}"/* || abort "Unable to remove files"
            log "Change directory ownership"
            chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || \
                abort "Unable to change ownership"
            log "SELinux: Allow Apache Web server to read/write files under ${INSTALL_DIR}/"
            chcon -t httpd_sys_content_t "${INSTALL_DIR}/" -R || \
                abort "Unable to give read permissions recursively"
            chcon -t httpd_sys_rw_content_t "${INSTALL_DIR}/" -R || \
                abort "Unable to give write permissions recursively"
            log "Restart Apache Web server"
            systemctl restart httpd.service || abort "Unable to restart Apache Web server"
            ;;
        *)
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

            if [[ "$?" -gt 0 ]]; then
                abort "Unable to create and edit file '/etc/apache2/sites-available/i-doit.conf'"
            fi

            log "Disable default VHost"
            "$a2_dis_site" 000-default || abort "Unable to disable default VHost"
            log "Cleanup VHost directory"
            rm -rf "${INSTALL_DIR}"/* || abort "Unable to remove files"
            log "Change directory ownership"
            chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || \
                abort "Unable to change ownership"
            log "Enable new VHost settings"
            "$a2_en_site" i-doit || abort "Unable to enable VHost settings"
            log "Enable Apache module rewrite"
            "$a2_en_mod" rewrite || abort "Unable to enable Apache module rewrite"
            log "Restart Apache Web server"
            systemctl restart apache2.service || abort "Unable to restart Apache Web server"
            ;;
    esac
}

function configureMariaDB {
    log "Configure MariaDB DBMS"

    local mysql_bin=`which mysql`
    local mariadb_config=""
    local mariadb_service="mysql.service"

    case "$OS" in
        "debian8")
            mariadb_config="/etc/mysql/conf.d/99-i-doit.cnf"
            ;;
        "debian9"|"ubuntu1604"|"ubuntu1610"|"ubuntu1704")
            secureMariaDB

            mariadb_config="/etc/mysql/mariadb.conf.d/99-i-doit.cnf"
            ;;
        "redhat73"|"centos73")
            secureMariaDB

            mariadb_config="/etc/my.cnf.d/99-i-doit.cnf"
            mariadb_service="mariadb.service"
            ;;
        *)
            abort "Unkown operating system '${OS}'!?!"
    esac

    log "Prepare shutdown of MariaDB"
    "$mysql_bin" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" -e"SET GLOBAL innodb_fast_shutdown = 0" || \
      abort "Unable to prepare shutdown"
    log "Stop MariaDB"
    systemctl stop "$mariadb_service" || abort "Unable to stop MariaDB"
    log "Move old MariaDB log files"
    mv /var/lib/mysql/ib_logfile[01] "$TMP_DIR" || abort "Unable to remove old log files"

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

    if [[ "$?" -gt 0 ]]; then
        abort "Unable to create and edit file '${mariadb_config}'"
    fi

    log "Start MariaDB"
    systemctl start "$mariadb_service" || abort "Unable to start MariaDB"
}

function secureMariaDB {
    local mysql_bin=`which mysql`

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
}

function prepareIDoit {
    log "Prepare i-doit"

    local file="${TMP_DIR}/i-doit.zip"

    if [[ ! -f "$file" ]]; then
        echo -n -e "Which variant of i-doit do you like to install? [PRO|open]: "

        local update_file_url=""

        read variant

        case "$variant" in
            ""|"PRO"|"Pro"|"pro")
                update_file_url="$UPDATE_FILE_PRO"
                log "Install i-doit pro"
                ;;
            "OPEN"|"Open"|"open")
                update_file_url="$UPDATE_FILE_OPEN"
                log "Install i-doit open"
                ;;
            *)
                abort "Unknown variant"
        esac

        log "Identify latest version of i-doit"
        test ! -f "$TMP_DIR/updates.xml" && (
            "$WGET_BIN" --quiet -O "$TMP_DIR/updates.xml" "$update_file_url" || \
            abort "Unable to fetch file from '${update_file_url}'"
        )

        local url=`cat "${TMP_DIR}/updates.xml" | \
            tail -n5 | \
            head -n1 | \
            sed "s/<filename>//" | \
            sed "s/<\/filename>//" | \
            sed "s/-update.zip/.zip/" | \
            awk '{print $1}'`

        test -n "$url" || abort "Missing URL"

        "$WGET_BIN" --quiet -O "$file" "$url" || \
            abort "Unable to download file"

        cp "$file" "${INSTALL_DIR}/i-doit.zip" || \
            abort "Unable to copy file"
    fi

    log "Unzip package"
    cd "$INSTALL_DIR"
    unzip -q i-doit.zip || abort "Unable to unzip file"

    log "Prepare files and directories"
    rm i-doit.zip || abort "Unable to remove downloaded file"
    chown "$APACHE_USER":"$APACHE_GROUP" -R . || abort "Unable to change ownership"
    find . -type d -name \* -exec chmod 775 {} \; || abort "Unable to change directory permissions"
    find . -type f -exec chmod 664 {} \; || abort "Unable to change file permissions"
    chmod 774 controller tenants import updatecheck *.sh setup/*.sh || \
        abort "Unable to change executable permissions"
}

function installIDoit {
    log "Install i-doit"

    echo -e -n "Please enter the MariaDB hostname [leave empty for '${MARIADB_HOSTNAME}']: "
    read answer
    if [[ -n "$answer" ]]; then
        MARIADB_HOSTNAME="$answer"
    fi

    ## install.sh only supports 'root' user and won't setup a dedicated 'idoit':
    #echo -e -n "Please enter the password for the new MariaDB user [leave empty for '${MARIADB_USER_PASSWORD}']: "
    #read answer
    #if [[ -n "$answer" ]]; then
    #    MARIADB_USER_PASSWORD="$answer"
    #fi

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
       -s "idoit_system" -m "idoit_data" -h "$MARIADB_HOSTNAME" -p "$MARIADB_SUPERUSER_PASSWORD" \
       -a "$IDOIT_ADMIN_CENTER_PASSWORD" -q || abort "i-doit setup script returned an error"
}

function deployScriptSettings {
    log "Deploy script settings"

    local settings_dir=`dirname "$SCRIPT_SETTINGS"`

    test -d "$settings_dir" || (
        mkdir -p "$settings_dir" || abort "Unable to create directory '$settings_dir'"
    )

    cat > "$SCRIPT_SETTINGS" << EOF
CONTROLLER_BIN="/usr/local/bin/idoit"
APACHE_USER="$APACHE_USER"
TENANT_DATABASE="idoit_data"
TENANT_ID="1"
MARIADB_USERNAME="root"
MARIADB_PASSWORD="$MARIADB_SUPERUSER_PASSWORD"
INSTANCE_PATH="$INSTALL_DIR"
IDOIT_USERNAME="admin"
IDOIT_PASSWORD="admin"
EOF

    if [[ "$?" -gt 0 ]]; then
        abort "Unable to create and edit file '/etc/apache2/sites-available/i-doit.conf'"
    fi
}

function deployController {
    log "Deploy controller script"

    local download_url="https://raw.githubusercontent.com/bheisig/i-doit-scripts/${VERSION}/idoit"
    local file="${TMP_DIR}/idoit"

    test ! -f "$file" && (
        "$WGET_BIN" --quiet -O "$file" "$download_url" || \
            abort "Unable to fetch file from '${download_url}'"
    )

    chmod 777 "$file" || abort "Unable to set executable bit"

    mv "$file" "$CONTROLLER_BIN" || abort "Unable to move script to '/usr/local/bin'"
}

function deployJobScript {
    local download_url="https://raw.githubusercontent.com/bheisig/i-doit-scripts/${VERSION}/idoit-jobs"
    local file="${TMP_DIR}/idoit-jobs"

    test ! -f "$file" && (
        "$WGET_BIN" --quiet -O "$file" "$download_url" || \
            abort "Unable to fetch file from '${download_url}'"
    )

    chmod 777 "$file" || abort "Unable to set executable bit"

    mv "$file" "$JOBS_BIN" || abort "Unable to move script to '/usr/local/bin'"
}

function deployCronJobs {
    local download_url="https://raw.githubusercontent.com/bheisig/i-doit-scripts/${VERSION}/cron"
    local file="$TMP_DIR/cron"

    test ! -f "$file" && (
        "$WGET_BIN" --quiet -O "$file" "$download_url" || \
            abort "Unable to fetch file from '${download_url}'"
    )

    sed -i -- "s/www-data/${APACHE_USER}/g" "$file" || abort "Unable to set Apache user"

    chmod 644 "$file" || abort "Unable to set read/write bits"

    mv "$file" "$CRON_FILE" || abort "Unable to move file to '/etc/cron.d/i-doit'"
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
    log ""
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
