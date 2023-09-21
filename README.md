# i-doit scripts

Useful scripts to maintain i-doit

![Build Status](https://github.com/i-doit/scripts/actions/workflows/main.yml/badge.svg)

## About

[i-doit](https://i-doit.com) is a software application for IT documentation and a CMDB (Configuration Management Database). This application is very useful to collect all your knowledge about the IT infrastructure you are dealing with. i-doit is a Web application and [has an exhausting API](https://kb.i-doit.com/pages/viewpage.action?pageId=37355644) which is very useful to automate your infrastructure.

## Install i-doit on a GNU/Linux operating system

The script [`idoit-install`](idoit-install) allows you to easily install the **latest version** of

-   i-doit pro or
-   i-doit open

on a **fresh installation of a GNU/Linux operating system**. Supported OSs are:

-   Debian GNU/Linux 10 "buster" , DebianGNU/Linux 11 (bullseye) (**recommended**)
-   Ubuntu Linux 18.04 LTS "bionic", 20.04 LTS "focal fossa" and 22.04 LTS "jammy jellyfish"
-   Red Hat Enterprise Linux (RHEL) 7 (deprecated) and (RHEL) 8
-   CentOS 7 (deprecated) and CentOS 8
-   SUSE Linux Enterprise Server 15, 15 SP1, 15 SP2 and 15 SP3
-   openSUSE "leap" 15, 15.1, 15.2 and 15.3

Before you execute this script you …

-   Must install one of the supported operating systems in **x86 64 bit** based on the [requirements mentioned in the i-doit knowledge base](https://kb.i-doit.com/display/en/System+Requirements) (excluding the LAMP stack)
-   Should **create a backup/snapshot of your system**
-   Must make sure that the system is allowed to access external Web services, for example package repositories and the i-doit website.

It's written in Bash so it needs **Bash version 4** or higher

The script includes several steps which are essential for i-doit:

-   Install needed distribution packages (LAMP stack incl. memcached)
-   Configure PHP
-   Configure Apache Web server (with PHP-FPM and Event MPM)
-   Configure MariaDB DBMS
-   Download and install the latest version of i-doit pro or open
-   Deploy cron jobs and an easy-to-use CLI tool for your i-doit instance
-   Deploy scripts to backup and restore your i-doit instance

All steps are based on information provided by the [i-doit knowledge base](https://kb.i-doit.com/display/en/).

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

It's also possible to run this script without any user interaction. For example, use `yes` to accept all default answers:

~~~ {.bash}
yes "" | ./idoit-install
~~~

Here is an example recording how to install i-doit on a fresh + clean Debian GNU/Linux 9 "stretch" in under 2 minutes (click on the picture):

[![asciicast](https://asciinema.org/a/130677.png)](https://asciinema.org/a/130677)

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

1.  [Install your license (only pro version)](https://kb.i-doit.com/display/en/Install+License)
2.  Document your IT (obviously ;-))

## Easy-use of the i-doit CLI

i-doit is shipped with a command-line tool called **console.php**. It is a little bit complicated to execute it because you have to change to i-doit's installation directory and you need the user rights of the Apache Web server. Additionally, you need to login before using one of the useful "commands".

To make sysadmin's life easier you may wrap the **console.php** in a separate script called [`idoit`](idoit). It changes to the right directory, gains proper rights and stores your credentials.

This script can be installed with `idoit-install` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

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
idoit notifications-send
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

This script can be installed with `idoit-install` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

Manually execute the jobs by running:

~~~ {.bash}
sudo idoit-jobs
~~~

You may want to execute this script automatically by creating a new cron job. There is already a file for that called `cron` which can be copied to `/etc/cron.d/i-doit`. Deploy this script and pre-configured cron jobs with `idoit-install` to run the jobs every night.

## Backup and restore i-doit

There are two useful scripts to backup ([`idoit-backup`](idoit-backup)) and restore ([`idoit-restore`](idoit-restore)) your i-doit instance. The backups contain the following data:

-   i-doit installation files including uploaded files and installed add-ons
-   Dumps of the system database and the first tenant's database

Backups are compressed and stored under `/var/backup/i-doit/`. They will be kept for at least 30 days.

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

[`idoit-pwd`](idoit-pwd) works smoothly with the [i-doit Virtual Appliance](https://github.com/i-doit/appliance):

~~~
idoit-pwd
~~~

## Deploy hot fixes

Sometimes there is a chance to find an unwanted behavior (a.k.a. bug) within i-doit or its add-ons. You want it to be fixed as soon as possible. You cannot wait for the next release.

For these conditions synetics provides [hot fixes](https://kb.i-doit.com/display/en/Hotfixes). Hot fixes are ZIP files which needs to be extracted in the root location of your i-doit instance. For an easy deployment you may use [`idoit-hotfix`](idoit-hotfix). Just copy the ZIP file via SSH to your GNU/Linux system, connect to this host via SSH and run the script:

~~~
idoit-hotfix /path/to/hotfix.zip
~~~

## Configuration settings

As already mentioned before some scripts provide configuration settings. These settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

There is a default configuration file you may use: [`i-doit.sh`](i-doit.sh)

| Setting               | Default Value                                                         | Description
| --------------------- | --------------------------------------------------------------------- | --------------------------------------------------------------
| `CONSOLE_BIN`         | `/usr/local/bin/idoit`                                                | See "Easy-use of the i-doit CLI"                              |
| `APACHE_USER`         | `www-data` (Debian/Ubuntu), `apache` (RHEL/CentOS), `wwwrun` (SLES)   | User who runs Apache Web server                               |
| `SYSTEM_DATABASE`     | `idoit_system`                                                        | i-doit's system database                                      |
| `TENANT_DATABASE`     | `idoit_data`                                                          | i-doit's tenant database                                      |
| `TENANT_ID`           | `1`                                                                   | Tenant ID                                                     |
| `MARIADB_USERNAME`    | `idoit`                                                               | MariaDB user for i-doit                                       |
| `MARIADB_PASSWORD`    | `idoit`                                                               | Password for this user                                        |
| `MARIADB_HOSTNAME`    | `localhost`                                                           | `localhost` uses a local UNIX socket for a better performance |
| `INSTANCE_PATH`       | `/var/www/html` (Debian/Ubuntu/RHEL/CentOS), `/srv/www/htdocs` (SLES) | In which directory is i-doit located?                         |
| `IDOIT_USERNAME`      | `admin`                                                               | i-doit user who executes CLI commands                         |
| `IDOIT_PASSWORD`      | `admin`                                                               | User's password                                               |
| `BACKUP_DIR`          | `/var/backups/i-doit`                                                 | Directory for local backups                                   |
| `BACKUP_AGE`          | `30`                                                                  | Max. age of backup files (in days); `0` disables it           |

The installation script `idoit-install` will ask the user to change most of the default values. **Pro tip:** You should set your own passwords. ;-) You may alter them with `idoit-pwd`.

## Contribute & support

Please, report any issues to [our issue tracker](https://github.com/i-doit/scripts/issues). Pull requests are very welcomed. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for more details.

## Copyright & license

Copyright (C) 2017-23 [synetics GmbH](https://i-doit.com/)

Licensed under the [GNU Affero GPL version 3 or later (AGPLv3+)](https://gnu.org/licenses/agpl.html). This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law.
