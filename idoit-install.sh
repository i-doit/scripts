#!/bin/bash

##
## Install i-doit on a GNU/Linux operating system
##

##
## Copyright (C) 2017-18 synetics GmbH, <https://i-doit.com/>
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

set -euo pipefail
IFS=$'\n\t'

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
MARIADB_IDOIT_USERNAME="idoit"
MARIADB_IDOIT_PASSWORD="idoit"
IDOIT_DEFAULT_TENANT="CMDB"
INSTALL_DIR="/var/www/html"
DATE=$(date +%Y-%m-%d)
TMP_DIR="/tmp/i-doit_${DATE}"
UPDATE_FILE_PRO="https://i-doit.com/updates.xml"
UPDATE_FILE_OPEN="https://i-doit.org/updates.xml"
OS=""
SCRIPT_SETTINGS="/etc/i-doit/i-doit.sh"
CONSOLE_BIN="/usr/local/bin/idoit"
JOBS_BIN="/usr/local/bin/idoit-jobs"
CRON_FILE="/etc/cron.d/i-doit"
BACKUP_DIR="/var/backups/i-doit"
BASENAME=$(basename "$0")
VERSION="0.9"

MARIADB_BIN=""
SUDO_BIN=""
UNZIP_BIN=""
WGET_BIN=""
PHP_BIN=""

##--------------------------------------------------------------------------------------------------

function execute {
    local status=0
    local ip_address=""

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
    log "    7) deploy scripts to backup and restore your i-doit instance"
    log ""
    log "You may skip any step if you like."
    log ""

    askYesNo "Do you really want to continue?" || ( log "Bye" && exit 0 )

    log "\\n--------------------------------------------------------------------------------\\n"

    identifyOS

    log "\\n--------------------------------------------------------------------------------\\n"

    log "This script needs Web access (HTTPS-only)."
    askNoYes "Do you want to configure a proxy server?" || configureProxy

    log "\\n--------------------------------------------------------------------------------\\n"

    askYesNo "Do you want to configure the operating system?" && configureOS

    checkRequirements

    log "\\n--------------------------------------------------------------------------------\\n"

    askYesNo "Do you want to configure the PHP environment?" && configurePHP

    log "\\n--------------------------------------------------------------------------------\\n"

    askYesNo "Do you want to configure the Apache Web server?" && configureApache

    log "\\n--------------------------------------------------------------------------------\\n"

    askYesNo "Do you want to configure MariaDB?" && configureMariaDB

    log "\\n--------------------------------------------------------------------------------\\n"

    if askYesNo "Do you want to download and install i-doit automatically?"; then
        prepareIDoit
        installIDoit

        ip_address=$(ip route get 1 | awk '{print $NF;exit}')

        log "Your setup is ready. Navigate to"
        log ""
        log "    http://${ip_address}/"
        log ""
        log "with your Web browser and login with username/password 'admin'"

        status=1
    else
        log "Your operating system is prepared for the installation of i-doit."
        log "To complete the setup please follow the instructions as described in the i-doit Knowledge Base:"
        log ""
        log "    https://kb.i-doit.com/display/en/Setup"
    fi

    if [[ "$status" = 1 ]]; then
        log "\\n--------------------------------------------------------------------------------\\n"


        if askYesNo "Do you want to configure i-doit cron jobs?"; then
            deployScriptSettings
            deployConsole
            deployJobScript
            deployCronJobs

            log "Cron jobs are successfully activated. To change the execution date and time please edit this file:"
            log ""
            log "    $CRON_FILE"
            log ""
            log "There is also a script available for all system users to execute the i-doit console command line tool:"
            log ""
            log "    idoit"
            log ""
            log "The needed cron jobs are defined here:"
            log ""
            log "    $JOBS_BIN"
            log ""
            log "If needed you can change the settings of both the i-doit console and the cron jobs:"
            log ""
            log "    $SCRIPT_SETTINGS"

            status=2
        fi
    fi

    if [[ "$status" = 2 ]]; then
        log "\\n--------------------------------------------------------------------------------\\n"

        if askYesNo "Do you want to backup i-doit automatically?"; then
            deployBackupAndRestore

            log "Backups are successfully activated. Each night a backup will be created. Backups will be kept for 30 days:"
            log ""
            log "    $BACKUP_DIR"
            log ""
            log "You may create a backup manually:"
            log ""
            log "    idoit-backup"
            log ""
            log "Of course, you are able to restore i-doit from the lastest backup:"
            log ""
            log "    idoit-restore"
            log ""
            log "Settings may be changed here:"
            log ""
            log "    $SCRIPT_SETTINGS"
        fi
    fi

    log "\\n--------------------------------------------------------------------------------\\n"

    case "$OS" in
        "ubuntu1604"|"ubuntu1610"|"ubuntu1704")
            log "To garantee that all your changes take effect you should restart your system."

            askYesNo "Do you want to restart your system NOW?" && systemctl -q reboot
            ;;
    esac
}

function identifyOS {
    local os_id=""
    local os_codename=""
    local os_description=""
    local os_release=""
    local os_major_release=""
    local os_patchlevel=""
    local arch=""

    if [[ -f "/etc/centos-release" ]]; then
        os_description=$(cat /etc/centos-release)
        os_release=$(grep -o '[0-9]\.[0-9]' /etc/centos-release)

        if [[ "$os_release" = "7.3" ]]; then
            log "Operating system identified as CentOS ${os_release}"
            OS="centos73"
        else
            abort "Operating system CentOS $os_release is not supported"
        fi

        APACHE_USER="apache"
        APACHE_GROUP="apache"
    elif [[ -f "/etc/redhat-release" ]]; then
        os_description=$(cat /etc/redhat-release)
        os_release=$(grep -o '[0-9]\.[0-9]' /etc/redhat-release)

        if [[ "$os_release" = "7.3" ]]; then
            log "Operating system identified as Red Hat Enterprise Linux (RHEL) ${os_release}"
            OS="rhel73"
        elif [[ "$os_release" = "7.4" ]]; then
            log "Operating system identified as Red Hat Enterprise Linux (RHEL) ${os_release}"
            OS="rhel74"
        else
            abort "Operating system Red Hat Enterprise Linux (RHEL) $os_release is not supported"
        fi

        APACHE_USER="apache"
        APACHE_GROUP="apache"
    elif [[ -f "/etc/SuSE-release" ]]; then
        os_description=$(head -n1 /etc/SuSE-release)
        os_release=$(grep "VERSION" /etc/SuSE-release | grep -o '[0-9]*')
        os_patchlevel=$(grep "PATCHLEVEL" /etc/SuSE-release | grep -o '[0-9]')

        if [[ "$os_release" = "12" && "$os_patchlevel" = "2" ]]; then
            log "Operating system identified as SUSE Linux Enterprise Server ${os_release} SP${os_patchlevel}"
            OS="sles12sp2"
        elif [[ "$os_release" = "12" && "$os_patchlevel" = "3" ]]; then
            log "Operating system identified as SUSE Linux Enterprise Server ${os_release} SP${os_patchlevel}"
            OS="sles12sp3"
        else
            abort "Operating system ${os_description} is not supported"
        fi

        INSTALL_DIR="/srv/www/htdocs"
        APACHE_USER="wwwrun"
        APACHE_GROUP="www"
    elif [[ -x "/usr/bin/lsb_release" ]]; then
        os_id=$(lsb_release --short --id)
        os_codename=$(lsb_release --short --codename)
        os_description=$(lsb_release --short --description)

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
        os_release=$(cat /etc/debian_version)
        os_major_release=$(awk -F "." '{print $1}' /etc/debian_version)

        if [[ "$os_major_release" = "8" ]]; then
            log "Operating system identified as Debian GNU/Linux ${os_release} (jessie)"
            log "Version 9 is recommended. Please consider to upgrade."
            OS="debian8"
        elif [[ "$os_major_release" = "9" ]]; then
            log "Operating system identified as Debian GNU/Linux ${os_release} (stretch)"
            OS="debian9"
        else
            abort "Operating system is based on Debian GNU/Linux $os_release but is not supported"
        fi
    else
        abort "Unable to identify operating system"
    fi

    arch=$(uname -m)

    if [[ "$arch" != "x86_64" ]]; then
        log "Attention! The system architecture is not x86 64 bit, but ${arch}. This could cause unwanted behaviour."
    fi
}

function checkRequirements {
    local failed=0

    MARIADB_BIN=$(command -v mysql)
    SUDO_BIN=$(command -v sudo)
    UNZIP_BIN=$(command -v unzip)
    WGET_BIN=$(command -v wget)
    PHP_BIN=$(command -v php)

    declare -A binaries
    binaries["mariabdb"]="$MARIADB_BIN"
    binaries["sudo"]="$SUDO_BIN"
    binaries["unzip"]="$UNZIP_BIN"
    binaries["wget"]="$WGET_BIN"
    binaries["php"]="$PHP_BIN"
    binaries["systemctl"]=$(command -v systemctl)
    binaries["apachectl"]=$(command -v apachectl)
    binaries["chronic"]=$(command -v chronic)

    for bin in "${!binaries[@]}"; do
        if [[ ! -x "${binaries[$bin]}" ]]; then
            log "$bin is missing"
            ((failed++))
        fi
    done

    case "$failed" in
        0)
            log "All requirements met. Excellent."
            ;;
        1)
            abort "Important requirement is missing. Please install and configure it."
            ;;
        *)
            abort "Important requirements are missing. Please install and configure them."
            ;;
    esac
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
        "rhel73"|"rhel74"|"centos73")
            configureRHEL
            ;;
        "sles12sp2"|"sles12sp3")
            configureSLES12
            ;;
        *)
            abort "Unkown operating system '${OS}'!?!"
    esac
}

function configureDebian8 {
    echo -n -e "Please enter a new password for MariaDB's super user 'root' [leave empty for '${MARIADB_SUPERUSER_PASSWORD}']: "

    read -r answer

    if [[ -n "$answer" ]]; then
      MARIADB_SUPERUSER_PASSWORD="$answer"
    fi

    log "Keep your Debian packages up-to-date"
    apt-get -qq -y update || abort "Unable to update Debian package repositories"
    apt-get -qq -y upgrade || abort "Unable to perform update of Debian packages"
    apt-get -qq -y clean || abort "Unable to cleanup Debian packages"
    apt-get -qq -y autoremove || abort "Unable to remove unnecessary Debian packages"

    log "Install required Debian packages"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password ${MARIADB_SUPERUSER_PASSWORD}" || \
        abort "Unable to set MariaDB super user password"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password ${MARIADB_SUPERUSER_PASSWORD}" || \
        abort "Unable to set MariaDB super user password"
    apt-get -qq -y install \
        apache2 libapache2-mod-php5 \
        php5 php5-cli php5-common php5-curl php5-gd php5-json php5-ldap php5-mcrypt php5-mysqlnd \
        php5-pgsql php5-memcached \
        mariadb-server mariadb-client \
        memcached unzip sudo moreutils || abort "Unable to install required Debian packages"
}

function configureDebian9 {
    log "Keep your Debian packages up-to-date"
    apt-get -qq --yes update || abort "Unable to update Debian package repositories"
    apt-get -qq --yes full-upgrade || abort "Unable to perform update of Debian packages"
    apt-get -qq --yes clean || abort "Unable to cleanup Debian packages"
    apt-get -qq --yes autoremove || abort "Unable to remove unnecessary Debian packages"

    log "Install required Debian packages"
    apt-get -qq --yes install \
        apache2 libapache2-mod-php \
        mariadb-client mariadb-server \
        php php-bcmath php-cli php-common php-curl php-gd php-imagick php-json php-ldap php-mcrypt \
        php-memcached php-mysql php-pgsql php-soap php-xml php-zip \
        memcached unzip sudo moreutils || abort "Unable to install required Debian packages"
}

function configureUbuntu1604 {
    log "Keep your Ubuntu packages up-to-date"
    apt-get -qq --yes update || abort "Unable to update Ubuntu package repositories"
    apt-get -qq --yes full-upgrade || abort "Unable to perform update of Ubuntu packages"
    apt-get -qq --yes clean || abort "Unable to cleanup Ubuntu packages"
    apt-get -qq --yes autoremove || abort "Unable to remove unnecessary Ubuntu packages"

    log "Install required Ubuntu packages"
    apt-get -qq --yes install \
        apache2 libapache2-mod-php \
        mariadb-client mariadb-server \
        php php-bcmath php-cli php-common php-curl php-gd php-imagick php-json php-ldap php-mcrypt \
        php-memcached php-mysql php-pgsql php-soap php-xml php-zip \
        memcached unzip moreutils || abort "Unable to install required Ubuntu packages"
}

function configureRHEL {
    local os_description=""
    local os_release=""
    local mariadb_url=""

    case "$OS" in
        "rhel73")
            os_description="Red Hat Enterprise Linux (RHEL)"
            os_release="7.3"
            mariadb_url="http://yum.mariadb.org/10.1/rhel7-amd64"
            ;;
        "rhel74")
            os_description="Red Hat Enterprise Linux (RHEL)"
            os_release="7.4"
            mariadb_url="http://yum.mariadb.org/10.1/rhel7-amd64"
            ;;
        "centos73")
            os_description="CentOS"
            os_release="7.3"
            mariadb_url="http://yum.mariadb.org/10.1/centos7-amd64"
            ;;
    esac

    log "Keep your yum packages up-to-date"
    yum --assumeyes --quiet update || abort "Unable to update yum packages"
    yum --assumeyes --quiet autoremove || abort "Unable to remove out-dated yum packages"
    yum --assumeyes --quiet clean all || abort "Unable to clean yum caches"
    rm -rf /var/cache/yum || abort "Unable to remove orphaned yum caches"

    log "Install some important packages, for example Apache Web server"
    yum --assumeyes --quiet install httpd unzip zip wget || \
        abort "Unable to install packages"

    log "$os_description $os_release has out-dated packages for PHP and MariaDB. This script will fix this issue by enabling these 3rd party repositories:"
    log ""
    log "    Webtatic.com for PHP 7.0"
    log "    Official MariaDB repository for MariaDB 10.1"
    log ""

    askYesNo "Do you agree with it?" || abort "Requirements for i-doit not met"

    log "Enable Webtatic repository"
    rpm --import --quiet https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 || \
        abort "Unable to import GPG key from EPEL"
    rpm -Uvh --quiet https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || \
        abort "Unable to install EPEL"
    rpm --import --quiet https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7 || \
        abort "Unable to import GPG key from Webtatic"
    rpm -Uvh --quiet https://mirror.webtatic.com/yum/el7/webtatic-release.rpm || \
        abort "Unable to enable Webtatic"

    log "Install PHP packages"
    yum --assumeyes --quiet install \
        php70w php70w-bcmath php70w-cli php70w-common php70w-gd php70w-ldap php70w-mbstring \
        php70w-mcrypt php70w-mysqlnd php70w-opcache php70w-pdo php70w-pecl-imagick \
        php70w-pecl-memcached php70w-pgsql php70w-soap php70w-xml || \
        abort "Unable to install PHP packages"

    log "Enable MariaDB repository"
    cat << EOF > /etc/yum.repos.d/MariaDB.repo || \
        abort "Unable to create and edit file '/etc/yum.repos.d/MariaDB.repo'"
# MariaDB 10.1 repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = $mariadb_url
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

    log "Install MariaDB packages"
    rpm --import --quiet https://yum.mariadb.org/RPM-GPG-KEY-MariaDB || \
        abort "Unable to import GPG key from MariaDB"
    ## Suppress unnecessary notices which could confuse the user:
    yum --assumeyes --quiet install MariaDB-server MariaDB-client &> /dev/null || \
        abort "Unable to install MariaDB"

    case "$OS" in
        "rhel73"|"rhel74")
            log "Enable required repository 'rhel-7-server-eus-optional-rpms'"
            subscription-manager repos --enable=rhel-7-server-eus-optional-rpms || \
                abort "Repository cannot be enabled"
            ## Install moreutils *after* EPEL *and* rhel-7-server-eus-optional-rpms have been
            ## enabled!
    esac

    log "Install 'moreutils'"
    yum --assumeyes --quiet install moreutils || \
        abort "Unable to install packages"

    log "Enable services"
    systemctl -q enable httpd.service || abort "Cannot enable Apache Web server"
    systemctl -q enable mariadb.service || abort "Cannot enable MariaDB server"

    log "Start services"
    systemctl -q start httpd.service || abort "Unable to start Apache Web server"
    systemctl -q start mariadb.service || abort "Unable to start MariaDB server"

    log "Allow incoming HTTP traffic"
    systemctl -q is-active firewalld.service || (
        log "Firewall is inactive. Start unit"
        systemctl -q start firewalld.service || abort "Unable to activate firewall"
    )
    firewall-cmd --permanent --add-service=http || abort "Unable to configure firewall"
    systemctl -q restart firewalld.service || abort "Unable to restart firewall"
}

function configureSLES12 {
    local dev_repos=""
    local web_repos=""
    local service_pack=""

    log "Keep your packages up-to-date"
    zypper --quiet --non-interactive refresh || abort "Unable to refresh software repositories"
    zypper --quiet --non-interactive update || abort "Unable to update software packages"

    case "$OS" in
        "sles12sp2")
            service_pack="2"
            ;;
        "sles12sp3")
            service_pack="3"
            ;;
    esac

    dev_repos=$(zypper repos -E | grep -c "SLE-SDK12-SP${service_pack}")
    web_repos=$(zypper repos -E | grep -c "SLE-Module-Web-Scripting12")

    if [[ "$dev_repos" -lt 2 || "$web_repos" -lt 2 ]]; then
        log "Please make sure that the following add-ons are activated in Yast:"
        log ""
        log "    SUSE Linux Enterprise Software Development Kit 12 SP${service_pack}"
        log "    Web and Scripting Module 12"
        log ""
        log "After activating these repositories run this script again."

        abort "Essential software repositories are missing"
    fi

    log "Install software packages"
    zypper --quiet --non-interactive install \
        apache2 apache2-mod_php7 \
        mariadb mariadb-client \
        memcached \
        php7 php7-bcmath php7-ctype php7-curl php7-gd php7-gettext php7-json php7-ldap \
        php7-mbstring php7-mcrypt php7-mysql php7-opcache php7-openssl php7-pdo php7-pgsql \
        php7-phar php7-soap php7-sockets php7-sqlite php7-xsl php7-zip php7-zlib || \
        abort "Unable to install required software packages"

    zypper --quiet --non-interactive clean || abort "Unable to clean up cached software packages"

    log "Enable services"
    systemctl -q enable apache2.service || abort "Cannot enable Apache Web server"
    systemctl -q enable mysql.service || abort "Cannot enable MariaDB server"

    log "Start services"
    systemctl -q start apache2.service || abort "Unable to start Apache Web server"
    systemctl -q start mysql.service || abort "Unable to start MariaDB server"

    log "Allow incoming HTTP traffic"
    SuSEfirewall2 open EXT TCP http || "Unable to open port 80"
    SuSEfirewall2 start || abort "Unable to restart firewall"

    log "Install 'chronic'"
    ## TODO: I know, this seems to be pretty ugly, but:
    ## Why the hack is moreutils not included in the standard repositories?!?
    wget --quiet -O "${TMP_DIR}/chronic" \
        https://git.joeyh.name/index.cgi/moreutils.git/plain/chronic || \
        abort "Unable to download 'chronic'"
    chmod +x "${TMP_DIR}/chronic" || abort "Unable to set executable bit"
    mv "${TMP_DIR}/chronic" /usr/bin || abort "Unable to move 'chronic' to '/usr/bin'"
    wget --quiet -O - https://cpanmin.us | perl - App::cpanminus || \
        abort "Unable to install cpanminus"
    cpanm --quiet --notest --install IPC::Run || abort "Unable to install Perl module IPC::Run"
}

function configureProxy {
    if [[ -n "${https_proxy+x}" ]]; then
        log "Found proxy settings in environment variable 'https_proxy': $https_proxy"

        askYesNo "Do you want to use this setting?" && return 0
    fi

    echo -n -e "Provide proxy settings [schema: https://username:password@proxy:port]: "

    read -r answer

    if [[ -n "$answer" ]]; then
        log "Set environment variable 'https_proxy' to '${answer}'"
        export https_proxy="$answer"
    else
        log "No settings found. Skip it."
    fi
}

function configurePHP {
    local ini_file=""
    local php_en_mod=""
    local php_version=""

    log "Configure PHP"

    php_version=$(php --version | head -n1 -c7 | tail -c3)

    if [[ "$OS" = "rhel73" || "$OS" = "rhel74" || "$OS" = "centos73" ]]; then
        ini_file="/etc/php.d/i-doit.ini"
    elif [[ "$OS" = "sles12sp2" || "$OS" = "sles12sp3" ]]; then
        ini_file="/etc/php7/conf.d/i-doit.ini"
    elif [[ "$php_version" = "7.0" ]]; then
        ini_file="/etc/php/7.0/mods-available/i-doit.ini"
        php_en_mod=$(command -v phpenmod)
    elif [[ "$php_version" = "5.6" ]]; then
        log "PHP 5.6 is installed, but 7.0 is recommended. Please consider to upgrade."
        ini_file="/etc/php5/mods-available/i-doit.ini"
        php_en_mod=$(command -v php5enmod)
    elif [[ "$php_version" = "5.5" || "$php_version" = "5.4" ]]; then
        log "PHP ${php_version} is way too old. Please upgrade."
        ini_file="/etc/php5/mods-available/i-doit.ini"
        php_en_mod=$(command -v php5enmod)
    else
        abort "PHP ${php_version} is not supported. Please upgrade/downgrade."
    fi

    log "Write PHP settings to '${ini_file}'"
    cat << EOF > "$ini_file" || abort "Unable to create and edit file '${ini_file}'"
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

    log "Append path to MariaDB UNIX socket to PHP settings"
    case "$OS" in
        "rhel73"|"rhel74"|"centos73")
            echo "mysqli.default_socket = /var/lib/mysql/mysql.sock" >> "$ini_file" || \
                abort "Unable to alter PHP settings"
            ;;
        "sles12sp2"|"sles12sp3")
            echo "mysqli.default_socket = /var/run/mysql/mysql.sock" >> "$ini_file" || \
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
    local a2_en_mod=""
    local a2_en_site=""
    local a2_dis_site=""

    log "Configure Apache Web server"

    case "$OS" in
        "rhel73"|"rhel74"|"centos73")
            cat << EOF > /etc/httpd/conf.d/i-doit.conf || \
                abort "Unable to create and edit file '/etc/httpd/conf.d/i-doit.conf'"
<Directory /var/www/html/>
        AllowOverride All
</Directory>
EOF

            test ! -d "$INSTALL_DIR" && (
                    mkdir -p "$INSTALL_DIR" || \
                        abort "Unable to create directory '${INSTALL_DIR}'"
            )

            log "Change directory ownership"
            chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || \
                abort "Unable to change ownership"
            log "SELinux: Allow Apache Web server to read/write files under ${INSTALL_DIR}/"
            chcon -t httpd_sys_content_t "${INSTALL_DIR}/" -R || \
                abort "Unable to give read permissions recursively"
            chcon -t httpd_sys_rw_content_t "${INSTALL_DIR}/" -R || \
                abort "Unable to give write permissions recursively"
            log "Restart Apache Web server"
            systemctl -q restart httpd.service || abort "Unable to restart Apache Web server"
            ;;
        "sles12sp2"|"sles12sp3")
            a2_en_mod=$(command -v a2enmod)

            cat << EOF > /etc/apache2/vhosts.d/i-doit.conf || \
                abort "Unable to create and edit file '/etc/apache2/vhosts.d/i-doit.conf'"
<VirtualHost *:80>
        ServerAdmin i-doit@example.net

        DocumentRoot ${INSTALL_DIR}/
        <Directory ${INSTALL_DIR}/>
                # See ${INSTALL_DIR}/.htaccess for details
                AllowOverride All
                Require all granted
        </Directory>

        LogLevel warn
        ErrorLog /var/log/apache2/error.log
        CustomLog /var/log/apache2/access.log combined
</VirtualHost>
EOF

            log "Change directory ownership"
            chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || \
                abort "Unable to change ownership"

            log "Enable Apache module for PHP 7"
            "$a2_en_mod" php7 || abort "Unable to enable Apache module php7"

            log "Enable Apache module rewrite"
            "$a2_en_mod" rewrite || abort "Unable to enable Apache module rewrite"

            log "Enable Apache module mod_access_compat"
            "$a2_en_mod" mod_access_compat || abort "Unable to enable Apache module mod_access_compat"

            log "Restart Apache Web server"
            systemctl -q restart apache2.service || abort "Unable to restart Apache Web server"
            ;;
        *)
            a2_en_site=$(command -v a2ensite)
            a2_dis_site=$(command -v a2dissite)
            a2_en_mod=$(command -v a2enmod)

            cat << EOF > /etc/apache2/sites-available/i-doit.conf || \
                abort "Unable to create and edit file '/etc/apache2/sites-available/i-doit.conf'"
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
            log "Change directory ownership"
            chown "$APACHE_USER":"$APACHE_GROUP" -R "${INSTALL_DIR}/" || \
                abort "Unable to change ownership"
            log "Enable new VHost settings"
            "$a2_en_site" i-doit || abort "Unable to enable VHost settings"
            log "Enable Apache module rewrite"
            "$a2_en_mod" rewrite || abort "Unable to enable Apache module rewrite"
            log "Restart Apache Web server"
            systemctl -q restart apache2.service || abort "Unable to restart Apache Web server"
            ;;
    esac
}

function configureMariaDB {
    local mariadb_config=""
    local mariadb_service="mysql.service"

    log "Configure MariaDB DBMS"

    case "$OS" in
        "debian8")
            mariadb_config="/etc/mysql/conf.d/99-i-doit.cnf"
            ;;
        "debian9"|"ubuntu1604"|"ubuntu1610"|"ubuntu1704")
            secureMariaDB

            mariadb_config="/etc/mysql/mariadb.conf.d/99-i-doit.cnf"
            ;;
        "rhel73"|"rhel74"|"centos73")
            secureMariaDB

            mariadb_config="/etc/my.cnf.d/99-i-doit.cnf"
            mariadb_service="mariadb.service"
            ;;
        "sles12sp2"|"sles12sp3")
            secureMariaDB

            mariadb_config="/etc/my.cnf.d/99-i-doit.cnf"
            ;;
        *)
            abort "Unkown operating system '${OS}'!?!"
    esac

    log "Prepare shutdown of MariaDB"
    "$MARIADB_BIN" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" -e"SET GLOBAL innodb_fast_shutdown = 0" || \
      abort "Unable to prepare shutdown"
    log "Stop MariaDB"
    systemctl -q stop "$mariadb_service" || abort "Unable to stop MariaDB"
    log "Move old MariaDB log files"
    mv /var/lib/mysql/ib_logfile[01] "$TMP_DIR" || abort "Unable to remove old log files"

    log "How many bytes of your RAM do you like to spend to MariaDB?"
    echo -n -e "You SHOULD give MariaDB ~ 50 per cent of your RAM [leave empty for '${MARIADB_INNODB_BUFFER_POOL_SIZE}']: "

    read -r answer

    if [[ -n "$answer" ]]; then
        MARIADB_INNODB_BUFFER_POOL_SIZE="$answer"
    fi

    log "Configure MariaDB settings"
    cat << EOF > "$mariadb_config" || abort "Unable to create and edit file '${mariadb_config}'"
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

innodb_stats_on_metadata = 0

sql-mode = ""
EOF

    log "Start MariaDB"
    systemctl -q start "$mariadb_service" || abort "Unable to start MariaDB"
}

function secureMariaDB {
    echo -n -e \
        "Please enter a new password for MariaDB's super user 'root' [leave empty for '${MARIADB_SUPERUSER_PASSWORD}']: "

    read -r answer

    if [[ -n "$answer" ]]; then
        MARIADB_SUPERUSER_PASSWORD="$answer"
    fi

    log "Set root password"
    "$MARIADB_BIN" -uroot \
        -e"UPDATE mysql.user SET Password=PASSWORD('${MARIADB_SUPERUSER_PASSWORD}') WHERE User='root';" || \
        abort "Unable to set root password"
    log "Allow root login only from localhost"
    "$MARIADB_BIN" -uroot \
        -e"DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" || \
        abort "Unable to disallow remote login for root"
    log "Remove anonymous user"
    "$MARIADB_BIN" -uroot \
        -e"DELETE FROM mysql.user WHERE User='';" || \
        abort "Unable to remove anonymous user"
    log "Remove test database"
    "$MARIADB_BIN" -uroot \
        -e"DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';" || \
        abort "Unable to remove test database"
    log "Allow to login user 'root' with password for MariaDB"
    "$MARIADB_BIN" -uroot \
        -e"UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';" || \
        abort "Unable to update user table"
    "$MARIADB_BIN" -uroot \
        -e"FLUSH PRIVILEGES;" || \
        abort "Unable to flush privileges"
}

function prepareIDoit {
    local file="${TMP_DIR}/i-doit.zip"
    local update_file_url=""
    local variant=""
    local parse_updates_script=""
    local url=""
    local version=""
    local release_date=""

    log "Cleanup VHost directory"
    rm -rf "${INSTALL_DIR:?}/"* || abort "Unable to remove files"
    rm -f "${INSTALL_DIR}"/.htaccess || abort "Unable to remove files"

    echo -n -e "Which variant of i-doit do you like to install? [PRO|open]: "

    read -r wanted_variant

    case "$wanted_variant" in
        ""|"PRO"|"Pro"|"pro")
            update_file_url="$UPDATE_FILE_PRO"
            variant="pro"
            ;;
        "OPEN"|"Open"|"open")
            update_file_url="$UPDATE_FILE_OPEN"
            variant="open"
            ;;
        *)
            abort "Unknown variant"
    esac

    log "Install i-doit $variant"

    log "Identify latest version of i-doit $variant"
    test ! -f "$TMP_DIR/updates.xml" && \
        "$WGET_BIN" --quiet -O "${TMP_DIR}/updates.xml" "$update_file_url"
    test -f "$TMP_DIR/updates.xml" || \
        abort "Unable to fetch file from '${update_file_url}'"

    parse_updates_script="${TMP_DIR}/parseupdates.php"

    cat << EOF > "$parse_updates_script" || \
        abort "Unable to create and edit file '${parse_updates_script}'"
<?php
\$attribute = \$argv[1];
\$xml = new SimpleXMLElement(trim(file_get_contents('${TMP_DIR}/updates.xml')));
echo \$xml->updates->update[count(\$xml->updates->update) - 1]->\$attribute;
EOF

    url=$($PHP_BIN "$parse_updates_script" "filename" | sed "s/-update.zip/.zip/")

    test -n "$url" || abort "Missing URL"

    version=$($PHP_BIN "$parse_updates_script" "version")

    test -n "$version" || abort "Missing version"

    release_date=$($PHP_BIN "$parse_updates_script" "release")

    test -n "$release_date" || abort "Missing release date"

    log "Download i-doit $variant $version (released on ${release_date})"

    "$WGET_BIN" --quiet -O "$file" "$url" || \
        abort "Unable to download installation file"

    cp "$file" "${INSTALL_DIR}/i-doit.zip" || \
        abort "Unable to copy installation file"

    log "Unzip package"
    cd "$INSTALL_DIR" || abort "Unable to change to installation directory '${INSTALL_DIR}'"
    "$UNZIP_BIN" -q i-doit.zip || abort "Unable to unzip file"

    log "Prepare files and directories"
    rm i-doit.zip || abort "Unable to remove downloaded file"
    chown "$APACHE_USER":"$APACHE_GROUP" -R . || abort "Unable to change ownership"
    find . -type d -name \* -exec chmod 775 {} \; || abort "Unable to change directory permissions"
    find . -type f -exec chmod 664 {} \; || abort "Unable to change file permissions"
    chmod 774 controller ./*.sh setup/*.sh || \
        abort "Unable to change executable permissions"
}

function installIDoit {
    local config_file=""

    log "Install i-doit"

    echo -e -n "Please enter the MariaDB hostname [leave empty for '${MARIADB_HOSTNAME}']: "
    read -r answer
    if [[ -n "$answer" ]]; then
        MARIADB_HOSTNAME="$answer"
    fi

    echo -e -n "Please enter the password for the new MariaDB user '${MARIADB_IDOIT_USERNAME}' [leave empty for '${MARIADB_IDOIT_PASSWORD}']: "
    read -r answer
    if [[ -n "$answer" ]]; then
        MARIADB_IDOIT_PASSWORD="$answer"
    fi

    echo -e -n "Please enter the password for the i-doit Admin Center [leave empty for '${IDOIT_ADMIN_CENTER_PASSWORD}']: "
    read -r answer
    if [[ -n "$answer" ]]; then
        IDOIT_ADMIN_CENTER_PASSWORD="$answer"
    fi

    echo -e -n "Please enter the name of the first tenant [leave empty for '${IDOIT_DEFAULT_TENANT}']: "
    read -r answer
    if [[ -n "$answer" ]]; then
        IDOIT_DEFAULT_TENANT="$answer"
    fi

    cd "${INSTALL_DIR}/setup" || abort "Directory '${INSTALL_DIR}/setup' not accessible"

    log "Run i-doit's setup script"
    ./install.sh -n "$IDOIT_DEFAULT_TENANT" \
        -s "idoit_system" -m "idoit_data" -h "$MARIADB_HOSTNAME" -p "$MARIADB_SUPERUSER_PASSWORD" \
        -a "$IDOIT_ADMIN_CENTER_PASSWORD" -q || abort "i-doit setup script returned an error"

    log "Grant MariaDB user '${MARIADB_IDOIT_USERNAME}' access to system database"
    "$MARIADB_BIN" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" \
        -e"GRANT ALL PRIVILEGES ON idoit_system.* TO '${MARIADB_IDOIT_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_IDOIT_PASSWORD}';" || \
        abort "Unable to grant access"

    log "Grant MariaDB user '${MARIADB_IDOIT_USERNAME}' access to tenant database"
    "$MARIADB_BIN" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" \
        -e"GRANT ALL PRIVILEGES ON idoit_data.* TO '${MARIADB_IDOIT_USERNAME}'@'localhost' IDENTIFIED BY '${MARIADB_IDOIT_PASSWORD}';" || \
        abort "Unable to grant access"

    log "Fix tenant table"
    "$MARIADB_BIN" -uroot -p"$MARIADB_SUPERUSER_PASSWORD" \
        -e"UPDATE idoit_system.isys_mandator SET isys_mandator__db_user = '${MARIADB_IDOIT_USERNAME}', isys_mandator__db_pass = '${MARIADB_IDOIT_PASSWORD}';" || \
        abort "Unable to fix tenant table"

    config_file="${INSTALL_DIR}/src/config.inc.php"

    log "Fix configuration file '${config_file}'"

    sed -i -- \
        "s/\"user\" => \"root\"/\"user\" => \"${MARIADB_IDOIT_USERNAME}\"/g" \
        "$config_file" || \
        abort "Unable to replace MariaDB username"

    sed -i -- \
        "s/\"pass\" => \"${MARIADB_SUPERUSER_PASSWORD}\"/\"pass\" => \"${MARIADB_IDOIT_PASSWORD}\"/g" \
        "$config_file" || \
        abort "Unable to replace MariaDB password"

    chown "$APACHE_USER":"$APACHE_GROUP" "$config_file" || abort "Unable to change ownership"
}

function deployScriptSettings {
    local settings_dir=""

    log "Deploy script settings"

    settings_dir=$(dirname "$SCRIPT_SETTINGS")

    test -d "$settings_dir" || (
        mkdir -p "$settings_dir" || abort "Unable to create directory '$settings_dir'"
    )

    cat << EOF > "$SCRIPT_SETTINGS" || \
        abort "Unable to create and edit file '${SCRIPT_SETTINGS}'"
CONSOLE_BIN="$CONSOLE_BIN"
APACHE_USER="$APACHE_USER"
SYSTEM_DATABASE="idoit_system"
TENANT_DATABASE="idoit_data"
TENANT_ID="1"
MARIADB_USERNAME="$MARIADB_IDOIT_USERNAME"
MARIADB_PASSWORD="$MARIADB_IDOIT_PASSWORD"
MARIADB_HOSTNAME="$MARIADB_HOSTNAME"
INSTANCE_PATH="$INSTALL_DIR"
IDOIT_USERNAME="admin"
IDOIT_PASSWORD="admin"
BACKUP_DIR="$BACKUP_DIR"
# Max. age of backup files (in days):
BACKUP_AGE=30
EOF
}

function deployConsole {
    log "Deploy i-doit console"
    deployScript idoit
}

function deployJobScript {
    log "Deploy i-doit jobs"
    deployScript idoit-jobs
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

function deployBackupAndRestore {
    log "Deploy backup and restore scripts"

    deployScript idoit-backup
    deployScript idoit-restore

    log "Create the first backup"
    /usr/local/bin/idoit-backup || abort "Backup script returned with error"
}

function deployScript {
    local file="$1"
    local tmp_file="${TMP_DIR}/$file"
    local url="https://raw.githubusercontent.com/bheisig/i-doit-scripts/${VERSION}/$file"

    log "Deploy script '$file'"

    test ! -f "$tmp_file" && (
        "$WGET_BIN" --quiet -O "$tmp_file" "$url" || \
            abort "Unable to fetch file from '${url}'"
    )

    chmod 777 "$tmp_file" || abort "Unable to set read/write/executable bits"

    mv "$tmp_file" "/usr/local/bin/$file" || abort "Unable to move file to '/usr/local/bin/'"
}

function setup {
    test "$(whoami)" = "root" || abort "Superuser rights required"

    mkdir -p "$TMP_DIR" || abort "Unable to create temporary directory"
}

function tearDown {
    test -d "$TMP_DIR" && ( rm -rf "$TMP_DIR" || echo "Failed to cleanup" 1>&2 )
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

    read -r answer

    case "$answer" in
        ""|"Y"|"Yes"|"y"|"yes")
            return 0
            ;;
        "No"|"no"|"n"|"N")
            return 1
            ;;
        *)
            log "Sorry, what do you mean?"
            askYesNo "$1"
    esac
}

function askNoYes {
    echo -n -e "$1 [y]es [N]o: "

    read -r answer

    case "$answer" in
        ""|"No"|"no"|"n"|"N")
            return 0
            ;;
        "Y"|"Yes"|"y"|"yes")
            return 1
            ;;
        *)
            log "Sorry, what do you mean?"
            askNoYes "$1"
    esac
}

function finish {
    log "Done. Have fun :-)"
    exit 0
}

function abort {
    echo -e "$1"  1>&2
    echo "Operation failed. Please check what is wrong and try again." 1>&2
    exit 1
}

##--------------------------------------------------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap tearDown EXIT

    ARGS=$(getopt \
        -o vh \
        --long help,version -- "$@" 2> /dev/null)

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
fi
