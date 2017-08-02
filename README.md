#   i-doit scripts

Useful scripts to maintain i-doit


##  About

[i-doit](https://i-doit.com) is a software application for IT documentation and a CMDB (Configuration Management Database). This application is very useful to collect all your knowledge about the IT infrastructure you are dealing with. i-doit is a Web application and [has an exhausting API](https://kb.i-doit.com/pages/viewpage.action?pageId=37355644) which is very useful to automate your infrastructure.


##  Install i-doit on a GNU/Linux operating system

The script `idoit-install.sh` allows you to easily install the **latest version** of

*   i-doit pro or
*   i-doit open

on a **fresh installation of a GNU/Linux operating system**. Supported OSs are:

*   Debian GNU/Linux 8 "jessie"
*   Debian GNU/Linux 9 "stretch" (**recommended**)
*   Ubuntu Linux 16.04 LTS "xenial"
*   Ubuntu Linux 16.10 "yakkety"
*   Ubuntu Linux 17.04 "zesty"
*   Red Hat Enterprise Linux (RHEL) 7.3 and 7.4
*   CentOS 7.3
*   SUSE Linux Enterprise Server 12 SP2

Before you execute this script you …

*   Must install one of the supported operating systems in x86 64 bit based on the [requirements mentioned in the i-doit knowledge base](https://kb.i-doit.com/display/en/System+Requirements) (excluding the LAMP stack)
*   Should create a backup/snapshot of your system
*   Must make sure that the system is allowed to access external Web services, for example package repositories and the i-doit website.

The script includes several steps which are essential for i-doit:

*   Install needed distribution packages (LAMP stack)
*   Configure PHP
*   Configure Apache Web server
*   Configure MariaDB DBMS
*   Download and install the latest version of i-doit pro or open
*   Deploy cron jobs and an easy-to-use CLI tool for your i-doit instance
*   Deploy scripts to backup and restore your i-doit instance

All steps are based on information provided by the [i-doit knowledge base](https://kb.i-doit.com/display/en/).


### Usage

Connect to your freshly installed OS, for example via **SSH**. Download the script `idoit-install.sh` and execute it with super-user rights (`root`).

Download:

~~~ {.bash}
wget https://raw.githubusercontent.com/bheisig/i-doit-scripts/master/idoit-install.sh
chmod 755 idoit-install.sh
~~~

Either run the script as `root`:

~~~ {.bash}
su
./idoit-install.sh
~~~

Or run it with `sudo` if available:

~~~ {.bash}
sudo ./idoit-install.sh
~~~

The script will ask you several questions. All of them have default answers. This allows you to just hit `ENTER` whenever a user interaction is needed.

Here is an example recording how to install i-doit on a fresh + clean Debian GNU/Linux 9 "stretch" in under 2 minutes (click on the picture):

[![asciicast](https://asciinema.org/a/130677.png)](https://asciinema.org/a/130677)


### Who should use this script?

You **should** install i-doit with this script if you agree with one or more of the following statements:

1)  _"I need a stable instance of i-doit with a good performance installed on a recommended operating system."_
2)  _"I am unsure how to maintain a GNU/Linux operating system."_
3)  _"I do not have the time to setup i-doit."_


### Who should not use this script?

You **should not** install i-doit with this script if you agree with one or more of the following statements:

1) _"I am an experienced GNU/Linux system administrator."_
2) _"i-doit will not be the only application on this system."_
3) _"I have special requirements to run i-doit."_


### What to do next?

There are several steps you still need to do by yourself:

1)  [Install your license (only pro version)](https://kb.i-doit.com/display/en/Install+License)
2)  Document your IT (obviously ;-))


##  Easy-use of the i-doit Controller

i-doit is shipped with a commandline tool called **Controller**. It is a little bit complicated to execute it because you have to change to i-doit's installation directory and you need the user rights of the Apache Web server. Additionally, you need to login before using one of the useful "handlers".

To make sysadmin's life easier you may wrap the **Controller** in a separate script called `idoit`. It changes to the right directory, gains proper rights and stores your credentials.

This script can be installed with `idoit-install.sh` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

To display the usage run:

~~~ {.bash}
idoit
~~~

Call a handler with optional arguments:

~~~ {.bash}
idoit HANDLER [OPTIONS]
~~~

For example, use the `notifications` handler to send emails:

~~~ {.bash}
idoit notifications
~~~


##  Run Important Jobs Automatically

There are some jobs which are essential for keeping your CMDB in a good shape. There is a script called `idoit-jobs` to handle some important jobs properly:

*   Clean up cache files
*   Clean up update packages
*   Archive older logbook entries
*   Re-create cache for user rights
*   Purge "unfinished" objects
*   Re-create the search index
*   Send notifications by email

This script can be installed with `idoit-install.sh` and will be copied to `/usr/local/bin/`. Its configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

Manually execute the jobs by running:

~~~ {.bash}
sudo idoit-jobs
~~~

You may want to execute this script automatically by creating a new cron job. There is already a file for that called `cron` which can be copied to `/etc/cron.d/i-doit`. It can be deployed with `install.sh` and run the jobs every night.


##  Backup and Restore i-doit

There are two useful scripts to backup and restore your i-doit instance. The backups contain the following data:

*   i-doit installation files including uploaded files and installed add-ons
*   Dumps of the system database and the first tenant's database

Backups are compressed and stored under `/var/backup/i-doit/`. They will be kept for at least 30 days.

Both scripts can easily be installed with `idoit-install.sh` and will be copied to `/usr/local/bin/`. Their configuration settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

Create a backup manually by running:

~~~ {.bash}
sudo idoit-backup
~~~

To restore the latest backup run:

~~~ {.bash}
sudo idoit-restore
~~~

You may automate your backups with a cron job. `idoit-install.sh` can handle it (see above).

Keep in mind that these scripts are just a little step for a good backup strategy. Consider to copy those backup files to another location. Additionally, if you installed i-doit within a virtual machine you should create snapshots.


##  Configuration Settings

As already mentioned before some scripts provide configuration settings. These settings may be altered in a file located under `/etc/i-doit/i-doit.sh`.

| Setting               | Default Value                                                         | Description
| --------------------- | --------------------------------------------------------------------- | --------------------------------------------------------------
| `CONTROLLER_BIN`      | `/usr/local/bin/idoit`                                                | See "Easy-use of the i-doit Controller"                       |
| `APACHE_USER`         | `www-data` (Debian/Ubuntu), `apache` (RHEL/CentOS), `wwwrun` (SLES)   | User who runs Apache Web server                               |
| `SYSTEM_DATABASE`     | `idoit_system`                                                        | i-doit's system database                                      |
| `TENANT_DATABASE`     | `idoit_data`                                                          | i-doit's tenant database                                      |
| `TENANT_ID`           | `1`                                                                   | Tenant ID                                                     |
| `MARIADB_USERNAME`    | `idoit`                                                               | MariaDB user for i-doit                                       |
| `MARIADB_PASSWORD`    | `idoit`                                                               | Password for this user                                        |
| `MARIADB_HOSTNAME`    | `localhost`                                                           | `localhost` uses a local UNIX socket for a better performance |
| `INSTANCE_PATH`       | `/var/www/html` (Debian/Ubuntu/RHEL/CentOS), `/srv/www/htdocs` (SLES) | In which directory is i-doit located?                         |
| `IDOIT_USERNAME`      | `admin`                                                               | i-doit user who executes controller handlers                  |
| `IDOIT_PASSWORD`      | `admin`                                                               | User's password                                               |
| `BACKUP_DIR`          | `/var/backups/i-doit`                                                 | Directory for local backups                                   |
| `BACKUP_AGE`          | `30`                                                                  | Max. age of backup files (in days); `0` disables it           |

The installation script `idoit-install.sh` will ask the user to change most of the default values. **Pro tip:** You should set your own passwords. ;-)


##  Contribute & Support

Please, report any issues to [our issue tracker](https://github.com/bheisig/i-doit-scripts/issues). Pull requests are very welcomed.


##  Copyright & License

Copyright (C) 2017 [synetics GmbH](https://i-doit.com/)

Licensed under the [GNU Affero GPL version 3 or later (AGPLv3+)](https://gnu.org/licenses/agpl.html). This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law.
