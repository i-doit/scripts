# i-doit scripts

Useful scripts to maintain i-doit

![Build Status](https://github.com/i-doit/scripts/actions/workflows/main.yml/badge.svg)

## About

[i-doit](https://i-doit.com) is a software application for IT documentation and a CMDB (Configuration Management Database). This application is very useful to collect all your knowledge about the IT infrastructure you are dealing with. i-doit is a Web application and [has an exhausting API](https://kb.i-doit.com/en/i-doit-add-ons/api/index.html) which is very useful to automate your infrastructure.

## Install i-doit on a GNU/Linux operating system

The script [`idoit-install`](idoit-install) allows you to easily install the **latest version** of

-   i-doit EVAL (default) or
-   i-doit pro or
-   i-doit open

on a **fresh installation of a GNU/Linux operating system**. Supported OSs are:

| Operating system                    | Notes                                                                                   |
| ----------------------------------- | --------------------------------------------------------------------------------------- |
| Debian GNU/Linux 13 "trixie"        | **Recommended**                                                                         |
| Ubuntu Linux 24.04 LTS "noble"      |                                                                                         |
| Red Hat Enterprise Linux (RHEL) 10  | Needs a registered system; enables BaseOS, AppStream and CodeReady Linux Builder        |
| Rocky Linux 10                      | Uses the CRB and EPEL repositories                                                      |
| Red Hat Enterprise Linux (RHEL) 9   | Needs a registered system; without the PHP extensions imagick and memcached             |
| SUSE Linux Enterprise Server 15 SP6 | Needs a registered system; activates the required SUSE modules and SUSE Package Hub     |

Other operating systems and versions are rejected.

Before you execute this script you …

-   Must install one of the supported operating systems in **x86 64 bit** based on the [requirements mentioned in the i-doit knowledge base](https://kb.i-doit.com/en/installation/system-requirements.html) (excluding the LAMP stack)
-   Should **create a backup/snapshot of your system**
-   Must make sure that the system is allowed to access external Web services, for example package repositories and the i-doit website.

It's written in Bash so it needs **Bash version 4** or higher

The script includes several steps which are essential for i-doit:

-   Install needed distribution packages (LAMP stack incl. memcached)
-   Configure PHP
-   Configure Apache Web server (with PHP-FPM; Event MPM, on SLES Prefork MPM)
-   Serve i-doit via HTTPS (see below)
-   Configure MariaDB DBMS
-   Download and install the latest version of i-doit pro or open
-   Deploy cron jobs and an easy-to-use CLI tool for your i-doit instance
-   Deploy scripts to backup and restore your i-doit instance

All steps are based on information provided by the [i-doit knowledge base](https://kb.i-doit.com/en/).

### Usage

Connect to your freshly installed OS, for example via **SSH**. Download the script `idoit-install` and execute it with super-user rights (`root`).

Download:

~~~ {.bash}
wget https://raw.githubusercontent.com/i-doit/scripts/main/idoit-install
~~~

Alternatively, use cURL for the download:

~~~ {.bash}
curl -LO https://raw.githubusercontent.com/i-doit/scripts/main/idoit-install
~~~

Make the script executable:

~~~ {.bash}
chmod 755 idoit-install
~~~

Either run the script as `root`:

~~~ {.bash}
su -
./idoit-install
~~~

Or run it with `sudo` if available:

~~~ {.bash}
sudo ./idoit-install
~~~

The script will ask you several questions. All of them have default answers. This allows you to just hit `ENTER` whenever a user interaction is needed.

Before the first change of the system, the script asks for the HTTPS mode, the certificate files, the host name and the variant, and it checks the presets (see below) for these settings, the RAM for MariaDB, the passwords and the e-mail address for cron jobs. Invalid answers are asked again. Invalid presets stop an unattended run with a message which names the variable or file to fix. Exception: the password of a remote MariaDB administrator is only checked later, when the database is set up.

Options:

~~~
-h, --help      Print usage
-v, --version   Print version
~~~

Any other option or argument prints the usage and exits with status 1.

Keep the other files of this repository next to `idoit-install` to deploy exactly these versions of the helper scripts. Otherwise, for example if the script is piped into `bash`, it downloads them from GitHub. By default it uses the Git tag of its own version (`idoit-install --version`), so this tag must exist in the repository. If you run a version from the `main` branch which is not tagged yet, set `SCRIPTS_REF=main`:

~~~ {.bash}
sudo SCRIPTS_REF=main ./idoit-install
~~~

### Passwords and credentials

The script does not use default passwords. For each account it asks for a password; leave the answer empty to let the script generate a random one (32 hexadecimal characters). All passwords which are set or generated during the installation are stored in `/root/i-doit-credentials.txt`, readable only by `root`:

-   MariaDB administrator (`idoit_admin`; MariaDB's `root` keeps logging in via UNIX socket), only for a local MariaDB server. For a remote server the script asks for the name and password of an existing administrator and does not store them.
-   MariaDB user for i-doit (`idoit`)
-   i-doit Admin Center (`admin`)
-   i-doit user `admin` of the first tenant

Each run appends its own section with a time stamp. If you run the script again, the last section holds the current passwords. Move these credentials to your password manager and delete the file afterwards.

The script only supports a fresh installation. It detects an existing one by a non-empty installation directory (a single `index.html` is ignored) or by an existing database `idoit_system` on the local MariaDB server. In unattended mode it refuses to overwrite it. In interactive mode it asks whether to continue; the default answer is No. If MariaDB is running but `root` is unable to log in via UNIX socket, the script stops because it cannot check for an existing installation. A remote MariaDB server is not checked.

### Security notes and limitations

-   `console.php install` and `console.php tenant-create` accept the passwords of the MariaDB administrator, the MariaDB user for i-doit, the Admin Center and the i-doit user `admin` only as command-line options. While these commands run (usually for a few seconds), other local users can read the passwords in the process list, for example with `ps`. Run the installation on a system without other users, or mount `/proc` with the option `hidepid=2` (or `hidepid=invisible`) so users only see their own processes. Change the passwords afterwards if untrusted users may have had access to the system during the installation.
-   `console.php` runs via `sudo`. `sudo` usually logs the whole command line including these passwords, for example to the auth log or the journal. Delete these log entries or change the passwords after the installation.
-   Passwords which you pass as environment variables on the command line end up in the shell history. Let the script ask for them or generate them, or preset them as `root` with `export` statements in a file which only `root` may read, and load it before you run the script, for example `. /root/idoit-install.env && ./idoit-install`.
-   The downloaded i-doit ZIP file is only checked for integrity with `unzip -t`. The script does not verify a checksum or a signature.
-   RHEL and Rocky Linux with SELinux in mode enforcing: If you connect JDisc Discovery later, the knowledge base optionally labels its port 25321/tcp for SELinux: `sudo semanage port -a -t postgresql_port_t -p tcp 25321`. The script does not run this command.

### Unattended installation

The script asks nothing if `IDOIT_UNATTENDED=1` is set or if stdin is not a terminal. Then it uses the default answers and the settings below. Hardware below the minimum requirements or an architecture other than x86 64 bit stops an unattended run. Example:

~~~ {.bash}
sudo IDOIT_UNATTENDED=1 IDOIT_VARIANT=eval IDOIT_HTTPS_MODE=selfsigned ./idoit-install
~~~

These settings may be set as environment variables:

| Variable                          | Default                                     | Description                                                                          |
| --------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------ |
| `IDOIT_UNATTENDED`                | `0`                                         | `1` disables all questions                                                           |
| `IDOIT_VARIANT`                   | `eval`                                      | `eval`, `pro` or `open`                                                              |
| `INSTALL_DIR`                     | `/var/www/html` (SLES: `/srv/www/htdocs`)   | Installation directory of i-doit                                                     |
| `IDOIT_DEFAULT_TENANT`            | `CMDB`                                      | Name of the first tenant                                                             |
| `IDOIT_ADMIN_CENTER_PASSWORD`     | empty (generated)                           | Password for the i-doit Admin Center                                                 |
| `IDOIT_ADMIN_PASSWORD`            | empty (generated)                           | Password for the i-doit user `admin`; must not contain `"`                           |
| `MARIADB_HOSTNAME`                | `localhost`                                 | Host of the MariaDB server; a remote server needs an existing administrator         |
| `MARIADB_SUPERUSER_USERNAME`      | `idoit_admin`                               | MariaDB administrator used by the installation                                       |
| `MARIADB_SUPERUSER_PASSWORD`      | empty (generated)                           | Password for this administrator; required for a remote server in unattended mode     |
| `MARIADB_IDOIT_USERNAME`          | `idoit`                                     | MariaDB user for i-doit                                                              |
| `MARIADB_IDOIT_PASSWORD`          | empty (generated)                           | Password for this user; must not contain `'`, `"` or `\`                             |
| `MARIADB_INNODB_BUFFER_POOL_SIZE` | `1G`                                        | RAM for MariaDB, about 50 per cent of the RAM is recommended                         |
| `CREDENTIALS_FILE`                | `/root/i-doit-credentials.txt`              | File for all passwords set during the installation                                   |
| `CONSOLE_CONFIG`                  | `/etc/i-doit/console.ini`                   | Credentials for the i-doit console used by the cron jobs                             |
| `CRON_MAILTO`                     | `root`                                      | E-mail address for errors of cron jobs                                               |
| `CRON_FILE`                       | `/etc/cron.d/i-doit`                        | File for the cron jobs                                                               |
| `SCRIPT_SETTINGS`                 | `/etc/i-doit/i-doit.sh`                     | Configuration file of the helper scripts; they always read `/etc/i-doit/i-doit.sh`   |
| `BACKUP_DIR`                      | `/var/backups/i-doit`                       | Directory for local backups                                                          |
| `UPDATE_FILE_PRO`                 | `https://i-doit.com/updates.xml`            | Update file to find the latest version of i-doit pro                                 |
| `UPDATE_FILE_OPEN`                | `https://i-doit.org/updates.xml`            | Update file to find the latest version of i-doit open                                |
| `UPDATE_FILE_EVAL`                | `https://eval-downloads.i-doit.com/idoit-eval-automatic.zip` | Download URL of i-doit EVAL                                         |
| `IDOIT_HTTPS_MODE`                | `selfsigned`                                | `none`, `selfsigned` or `custom`                                                     |
| `IDOIT_HTTPS_REDIRECT`            | `yes`                                       | Redirect HTTP to HTTPS (`yes` or `no`)                                               |
| `IDOIT_HSTS`                      | `no`                                        | Send the header `Strict-Transport-Security` (`yes` or `no`)                          |
| `IDOIT_FQDN`                      | output of `hostname -f`                     | Host name in the certificate                                                         |
| `TLS_DIR`                         | `/etc/i-doit/tls`                           | Directory for certificate and private key                                            |
| `IDOIT_TLS_CERT`                  | empty                                       | Own certificate (PEM) for mode `custom`                                              |
| `IDOIT_TLS_KEY`                   | empty                                       | Unencrypted private key (PEM) for mode `custom`                                      |
| `IDOIT_TLS_CHAIN`                 | empty                                       | Optional intermediate certificates (PEM) for mode `custom`                           |
| `SCRIPTS_REF`                     | version of `idoit-install`                  | Git ref for helper files not next to the script; tag must exist or use `main`        |
| `https_proxy`                     | not set                                     | Proxy, for example `http://proxy.example.net:3128`, see below                        |

The script can also ask for `https_proxy`. It only exports this variable to `wget` and the package managers (`apt-get`, `dnf`, `zypper`). It also uses the same proxy for `http_proxy`, unless `http_proxy` is already set, because package mirrors via plain HTTP only use `http_proxy`. It writes no proxy configuration for the package managers.

### HTTPS

By default, the script serves i-doit via HTTPS and redirects HTTP to HTTPS. It enables `mod_ssl` and writes a separate virtual host. If `firewalld` or `ufw` is active, the script opens port 80 in every HTTPS mode while it configures the operating system (`ufw` only on Debian and Ubuntu) and port 443 only if HTTPS is enabled. Choose one of these modes with `IDOIT_HTTPS_MODE` or answer the question:

-   `selfsigned` (default): The script creates a self-signed certificate for the host name and the primary IP address. Browsers will show a warning until you replace it. The script warns if the host name is not fully qualified; set `IDOIT_FQDN` in this case. On a rerun, certificate and key in `TLS_DIR` are kept only if they match and the certificate is not expired; remove them to get a new certificate.
-   `custom`: The script installs your own certificate, private key and optional chain from `IDOIT_TLS_CERT`, `IDOIT_TLS_KEY` and `IDOIT_TLS_CHAIN`. The chain is appended to the certificate. If the key is encrypted or does not match the certificate, the script asks again in interactive mode and stops in unattended mode.
-   `none`: i-doit is only served via HTTP.

Certificate and key are stored as `${TLS_DIR}/i-doit.crt` and `${TLS_DIR}/i-doit.key` (default `/etc/i-doit/tls/`). The key gets mode `0600`, the directory mode `0700`. HSTS (`IDOIT_HSTS=yes`) sends `max-age=31536000`; enable it only if the certificate is trusted by all clients.

### Who should use this script?

You **should** install i-doit with this script if you agree with one or more of the following statements:

1.  _"I need a stable instance of i-doit with a good performance installed on a recommended operating system."_
2.  _"I am unsure how to maintain a GNU/Linux operating system."_
3.  _"I do not have the time to setup i-doit."_

### Who should not use this script?

You **should not** install i-doit with this script if you agree with one or more of the following statements:

1.  _"I am an experienced GNU/Linux system administrator."_
2.  _"i-doit will not be the only application on this system."_
3.  _"I have special requirements to run i-doit."_

### What to do next?

There are several steps you still need to do by yourself:

1.  [Install your license (only pro version)](https://kb.i-doit.com/en/maintenance-and-operation/licensing.html)
2.  Document your IT (obviously ;-))

## Easy-use of the i-doit CLI

i-doit is shipped with a command-line tool called **console.php**. It is a little bit complicated to execute it because you have to change to i-doit's installation directory and you need the user rights of the Apache Web server. Additionally, you need to login before using one of the useful "commands".

To make sysadmin's life easier you may wrap the **console.php** in a separate script called [`idoit`](idoit). It changes to the right directory and gains proper rights.

This script can be installed with `idoit-install` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`. This file contains the password of the MariaDB user for i-doit, so only `root` may read it. Therefore `idoit` and the other scripts must be run as `root`.

`idoit-install` stores the credentials of the i-doit user `admin` in `/etc/i-doit/console.ini` (readable by `root` and the Apache group). Pass this [configuration file](https://kb.i-doit.com/en/automation-and-integration/cli/configuration-files.html) with `-c` to commands instead of typing the password on the command line.

To display the usage run:

~~~ {.bash}
idoit
~~~

Call a handler with optional arguments:

~~~ {.bash}
idoit COMMAND [OPTIONS]
~~~

For example, use the `notifications-send` handler to send emails:

~~~ {.bash}
idoit notifications-send -c /etc/i-doit/console.ini
~~~

## Run important jobs automatically

There are some jobs which are essential for keeping your CMDB in a good shape. There is a script called [`idoit-jobs`](idoit-jobs) to handle some important jobs properly:

-   Clean up cache files
-   Clean up update packages
-   Archive older logbook entries
-   Re-create cache for user rights
-   Purge "unfinished" objects
-   Re-create the search index
-   Send notifications by email

This script can be installed with `idoit-install` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`. It logs in with the credentials from `/etc/i-doit/console.ini`.

Manually execute the jobs by running:

~~~ {.bash}
sudo idoit-jobs
~~~

You may want to execute this script automatically by creating a new cron job. There is already a file for that called [`cron`](cron) which can be copied to `/etc/cron.d/i-doit`. Deploy this script and pre-configured cron jobs with `idoit-install` to run the backup at 04:05 and the jobs at 05:05 every night. Both run as `root` with `chronic`, so only errors are sent by e-mail to the address in `MAILTO`. See also [how to set up cron jobs](https://kb.i-doit.com/en/maintenance-and-operation/set-up-cron-jobs.html).

## Backup and restore i-doit

There are two useful scripts to backup ([`idoit-backup`](idoit-backup)) and restore ([`idoit-restore`](idoit-restore)) your i-doit instance. The backups contain the following data:

-   i-doit installation files including uploaded files and installed add-ons
-   Dumps of the system database and the first tenant's database

Backups are compressed and stored under `/var/backups/i-doit/`. They will be kept for at least 30 days.

Both scripts can easily be installed with `idoit-install` and will be copied to `/usr/local/bin/`. Their configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

Create a backup manually by running:

~~~ {.bash}
sudo idoit-backup
~~~

To restore the latest backup run:

~~~ {.bash}
sudo idoit-restore
~~~

You may automate your backups with a cron job. `idoit-install` can handle it (see above).

Keep in mind that these scripts are just a little step for a good backup strategy. Consider to copy those backup files to another location. Additionally, if you installed i-doit within a virtual machine you should create snapshots.

## Collect data about i-doit, installed add-ons and your system

Works smoothly with the i-doit Virtual Appliance:

~~~
idoit-support
~~~

## Alter passwords for various users and remove default users

[`idoit-pwd`](idoit-pwd) allows you to change the password for the i-doit user who executes CLI commands. Additionally, it can be used to remove the default `admin` user and create a new one with a custom username and password.

~~~
idoit-pwd
~~~

If you change the password of the i-doit user `admin` or delete this user, update `/etc/i-doit/console.ini`. Otherwise the cron jobs fail.

## Deploy hot fixes

Sometimes there is a chance to find an unwanted behavior (a.k.a. bug) within i-doit or its add-ons. You want it to be fixed as soon as possible. You cannot wait for the next release.

For these conditions synetics provides [hot fixes](https://kb.i-doit.com/en/administration/hotfixes/index.html). Hot fixes are ZIP files which needs to be extracted in the root location of your i-doit instance. For an easy deployment you may use [`idoit-hotfix`](idoit-hotfix). Just copy the ZIP file via SSH to your GNU/Linux system, connect to this host via SSH and run the script:

~~~
idoit-hotfix /path/to/hotfix.zip
~~~

## Configuration settings

As already mentioned before some scripts provide configuration settings. These settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

There is a default configuration file you may use: [`i-doit.sh`](i-doit.sh)

| Setting            | Default Value                                                          | Description                                                   |
| ------------------ | ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| `CONSOLE_BIN`      | `/usr/local/bin/idoit`                                                 | See "Easy-use of the i-doit CLI"                              |
| `CONSOLE_CONFIG`   | `/etc/i-doit/console.ini`                                              | Credentials of the i-doit user who executes the jobs          |
| `APACHE_USER`      | `www-data` (Debian/Ubuntu), `apache` (RHEL/Rocky), `wwwrun` (SLES)     | User who runs Apache Web server                               |
| `SYSTEM_DATABASE`  | `idoit_system`                                                         | i-doit's system database                                      |
| `TENANT_DATABASE`  | `idoit_data`                                                           | i-doit's tenant database                                      |
| `TENANT_ID`        | `1`                                                                    | Tenant ID                                                     |
| `MARIADB_USERNAME` | `idoit`                                                                | MariaDB user for i-doit                                       |
| `MARIADB_PASSWORD` | empty (set by `idoit-install`)                                         | Password for this user                                        |
| `MARIADB_HOSTNAME` | `localhost`                                                            | `localhost` uses a local UNIX socket for a better performance |
| `INSTANCE_PATH`    | `/var/www/html` (Debian/Ubuntu/RHEL/Rocky), `/srv/www/htdocs` (SLES)   | In which directory is i-doit located?                         |
| `BACKUP_DIR`       | `/var/backups/i-doit`                                                  | Directory for local backups                                   |
| `BACKUP_AGE`       | `30`                                                                   | Max. age of backup files (in days); `0` disables it           |

`idoit-install` writes this file with the values of your installation and makes it readable only by `root`.

## Contribute & support

Please, report any issues to [our issue tracker](https://github.com/i-doit/scripts/issues). Pull requests are very welcomed. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for more details.

## Copyright & license

Copyright (C) 2017-26 [i-doit GmbH](https://i-doit.com/)

Licensed under the [GNU Affero GPL version 3 or later (AGPLv3+)](https://gnu.org/licenses/agpl.html). This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law.
