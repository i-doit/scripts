# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased][]

## [0.14][] – 2026-09-30

Note: We moved this repository to [a new location](http://github.com/i-doit/scripts).

### Security

-   `idoit-install`: Known limitation: `console.php` only accepts the passwords for the installation and the first tenant as command-line options, so local users can read them in the process list while these commands run. See "Security notes and limitations" in the README.

### Added

-   `idoit-install`: Add support for Debian GNU/Linux 13 "trixie", Ubuntu Linux 24.04 LTS, RHEL 9, RHEL 10, Rocky Linux 10 and SLES 15 SP6
-   `idoit-install`: Add EVAL installation routine and set it as default
-   `idoit-install`: Create the first tenant via `console.php`; its name defaults to `IDOIT_DEFAULT_TENANT`
-   `idoit-install`: Add unattended mode (`IDOIT_UNATTENDED=1` or no terminal on stdin)
-   `idoit-install`: Serve i-doit via HTTPS with a self-signed certificate by default or an own certificate
-   `idoit-install`: Store all passwords set during the installation in `/root/i-doit-credentials.txt`, readable only by `root`
-   `idoit-install`: Deploy `/etc/i-doit/console.ini` with the credentials for the cron jobs
-   `idoit-install`: Ask for the e-mail address for errors of cron jobs (`CRON_MAILTO`)
-   `idoit-install`: Install and check the PHP extensions `imagick` and `xmlwriter`
-   `idoit-install`: Enable the Apache modules `expires` and `headers` on Debian and Ubuntu

### Changed

-   `idoit-install`: Generate random passwords instead of using default passwords
-   `idoit-install`: Create the MariaDB administrator `idoit_admin`; MariaDB's `root` keeps logging in via UNIX socket
-   `idoit-install`: Deploy helper scripts from the directory of `idoit-install` or from the Git tag of this version (`SCRIPTS_REF`) instead of the main branch
-   `idoit-install`: Use PHP 8 on SLES 15 SP6
-   `idoit-install`: Align MariaDB settings with the knowledge base
-   `idoit-install`: Install i-doit via `console.php`
-   `idoit-jobs`: Read the i-doit credentials from `CONSOLE_CONFIG`
-   `cron`: Run the jobs as `root` and send errors to `MAILTO`
-   `i-doit.sh`: Remove `IDOIT_USERNAME` and `IDOIT_PASSWORD`, add `CONSOLE_CONFIG`; only `root` may read this file
-   `README.md`: Describe supported platforms, unattended mode, all settings and HTTPS

### Removed

-   `idoit-install`: Remove support for all operating systems not listed above, including Debian 12, older Ubuntu releases, RHEL 8, CentOS and openSUSE
-   `idoit-install`: Remove outdated i-doit controller

### Fixed

-   `idoit-install`: Stop on errors inside installation steps
-   `idoit-install`: Use the proxy for package mirrors via plain HTTP, too
-   `idoit-install`: Keep the database password out of the process list for backup and restore
-   `idoit-install`: Keep logs private and make reruns safe
-   `idoit-install`: Stop before the first change of the system if i-doit is already installed
-   `idoit-install`: Label the i-doit directory persistently for SELinux
-   `idoit-install`: Set the AppArmor profile of PHP-FPM to complain mode on SLES
-   `idoit-install`: Install and enable a cron daemon and the CA certificates on minimal systems
-   `idoit-install`: Stop with a clear message if basic commands like `getopt` or `vmstat` are missing
-   `idoit-install`: Install available updates on RHEL and Rocky Linux instead of stopping, like on the other platforms
-   `idoit-install`: Find local helper files after a change of the working directory and check all helper files before the first change of the system
-   `idoit-install`: Open TCP port 80 in an active `ufw` firewall on Debian and Ubuntu in every HTTPS mode, including `none`
-   `idoit-install`: Reject a password for the MariaDB user of i-doit that contains `'`, `"` or `\` because `console.php` cannot store it correctly, and check a preset password before the first change of the system
-   `idoit-install`: Check the variant, the HTTPS settings, the host name in the certificate, the size of the InnoDB buffer pool, the password of the i-doit user `admin` and `CRON_MAILTO` before the first change of the system, and ask again after an invalid answer instead of stopping
-   `idoit-install`: Print the usage on an unknown option or argument instead of stopping without a message or ignoring the argument
-   `idoit-install`: Stop with a clear message if the download URL, version or release date of i-doit cannot be read or the `.htaccess` template is missing
-   `idoit-install`: Store generated passwords before `console.php` uses them, so they are not lost if it fails
-   `idoit-install`: Stop if MariaDB is running but `root` cannot log in to check for an existing installation
-   `idoit-install`: Activate the Desktop Applications Module on SLES because `php8-imagick` needs ImageMagick from it
-   `idoit-install`: Activate the Development Tools Module on SLES because `chronic` needs `perl-IO-Tty` from it, and activate the Basesystem and Server Applications Modules the other modules depend on
-   `idoit-install`: Create a custom installation directory (`INSTALL_DIR`) on SLES, Debian and Ubuntu before changing its ownership
-   `idoit-install`: Grant access to a custom installation directory (`INSTALL_DIR`) in the Apache VHosts and stop enabling the Apache module `access_compat` on SLES, which i-doit does not need
-   `idoit-install`: Enable the BaseOS and AppStream repositories on RHEL if they are missing on a registered system, for example when registering RHEL 10 disabled the repository management of `subscription-manager`, and stop with a clear message on a system that is not registered
-   `idoit-install`: Fix broken patch of i-doit's configuration file `src/config.inc.php`
-   `idoit-install`: Fix hardware checks because of wrong locale (found on Ubuntu 18.04 LTS)
-   `idoit-install`: Fix links to the knowledge base
-   `idoit-support`: Add missing destination for file `appliance_version`

## [0.13][] – 2019-07-10

### Added

-   `idoit-install`: Add support for Debian GNU/Linux 10 "buster"
-   `idoit-install`: Add support for Red Hat Enterprise Linux (RHEL) 8
-   `idoit-install`: Add support for SLES 12 SP4
-   `idoit-install`: Add support for SLES 15 SP1
-   `idoit-install`: Add support for PHP 7.3
-   `idoit-install`: Add support for MariaDB 10.2 and 10.3
-   `idoit-install`: Add experimental support for PHP 7.4
-   `idoit-install`: Download scripts from master branch to stay up-to-date
-   `idoit-install`: Activate Web and Scripting Module on SLES 15 automatically
-   `idoit-install`: Activate Web and Scripting Module and Development Kit on SLES 12 automatically
-   `idoit-install`: Check for already enabled EPEL and Webtatic repositories on RHEL 7/CentOS 7

### Changed

-   `idoit-install`: Print warnings for non-supported operating systems
-   `idoit-install`: Split checks for hardware and software requirements into two parts
-   `idoit-install`: Run on Debian-based OS in non-interactive mode to prevent warnings
-   `idoit-install`: Remove support for Debian GNU/Linux 8 "jessie" because of outdated packages
-   `idoit-install`: Print warning for out-dated SLES 12 versions
-   `idoit-install`: Do not require Development Tools Modules on SLES 15
-   `idoit-install`: Switch to MariaDB 7.3 on RHEL/CentOS 7
-   `idoit-install`: Do not ask to restart system on Ubuntu 16.04
-   `idoit-jobs`: Disable resetting PHP OpCache
-   `idoit-jobs`: Disable rebuilding i-doit's own cache

### Fixed

-   `cron`: Run backup with super-user rights (`root`)
-   `idoit-install`: Remove out-dated PHP module `mcrypt` when possible
-   `idoit-install`: Remove unnecessary PHP module `imagick`
-   `idoit-install`: Use firewalld on SLES 15
-   `idoit-install`: Use proper location for MariaDB configuration file on SLES 12

## [0.12][] – 2018-12-21

Happy holidays 🎄

### Added

-   `idoit-install`: Add support for Ubuntu Linux 18.04 LTS "bionic"
-   `idoit-install`: Add support for CentOS 7.6
-   `idoit-install`: Add support for RHEL 7.6
-   `idoit-install`: Add support for SLES 15
-   `idoit-install`: Add support for SLES 12 SP4
-   `idoit-install`: Test more PHP extensions whether they are loaded
-   `idoit-jobs`: Clear PHP OpCache via local HTTP request
-   `idoit-jobs`: Re-cache by requesting i-doit Web GUI
-   `idoit-support`: Collect information about hardware, installed software and systemd

### Changed

-   `idoit-install`: Switch from Apache module php to fastcgi with php-fpm
-   `idoit-install`: Merge i-doit's .htaccess files into Apache site configuration
-   `idoit-install`: Switch from Apache module mpm_prefork to mpm_event (except on SLES)
-   `idoit-install`: Set locale to US or GB English because interaction with some commands would fail (for example, `vmstat` on Ubuntu Linux)
-   `idoit-install`: To install PHP extension imagick on SLES the 3rd-party repository `server:php:extensions:php7` from OpenSUSE is required
-   `idoit-install`: Do not abort installation if user doesn't enable EPEL on RHEL/CentOS
-   `idoit-install`: Ask user to continue if architecture is not x86 64 bit
-   `idoit-install`: Remove support for Ubuntu Linux 16.10 "yakkety" (EOL)
-   `idoit-install`: Remove support for Ubuntu Linux 17.04 "zesty" (EOL)
-   `idoit-jobs`: Clear caches at the end of all jobs

### Fixed

-   `idoit-install`: Install missing PHP7 extensions fileinfo and imagick (SLES12)
-   `idoit-install`: Prevent MariaDB service failing on startup/shutdown (Ubuntu Linux)
-   `idoit-install`: Enable and start memcached service (RHEL/CentOS/SLES12)
-   `idoit-install`: Install missing PHP OpCache on Debian GNU/Linux and Ubuntu

## [0.11][] – 2018-07-13

### Added

-   `idoit-install`: Re-name file name
-   `idoit-install`: Check for installed PHP extensions
-   `idoit-install`: Add support for PHP 7.1
-   `idoit-install`: Configure script by global variables
-   `idoit-support`: Collect data about i-doit, installed add-ons and your system
-   `idoit-pwd`: Alter passwords for various users and remove default users
-   `i-doit.sh`: Default configuration file used by most scripts

### Changed

-   `idoit-install`: Install PHP 7.1 from Webtatic.com on RHEL/CentOS

### Fixed

-   `idoit-install`: Install PHP extension `mbstring` on Debian GNU/Linux and Ubuntu Linux

## [0.10][] – 2018-07-02

### Added

-   Support for Red Hat Enterprise Linux (RHEL) 7.5
-   Support for CentOS 7.4 and 7.5
-   Match available CPU cores and RAM with requirements
-   `idoit-hotfix`: Deploy hot fixes

### Changed

-   `idoit-jobs`: use improved search indexer since i-doit 1.11

### Fixed

-   Do not set executable bit for out-dated files (since i-doit 1.10.1)
-   Cancel script if user likes to
-   SLES: install PHP modules bz2, memcached and posix

## [0.9][] – 2017-12-19

### Added

-   Download files via proxy server if needed

### Changed

-   Switch from `controller` CLI to `php console.php`
-   Disable MariaDB setting `innodb_stats_on_metadata`
-   Use already downloaded file `updates.xml` to check for latest i-doit version

### Fixed

-   Installer is unable to identify Ubuntu and SLES properly, says these OSs are unsupported

## [0.8][] – 2017-09-18

### Added

-   Support for SUSE Linux Enterprise Server (SLES) 12 SP3

### Fixed

-   Jobs: Truncate search index
-   Use apt-get on Debian GNU/Linux 8

## [0.7][] – 2017-09-02

### Added

-   Support for Red Hat Enterprise Linux (RHEL) 7.4
-   Show version and release date of i-doit
-   Clean up VHost directory just before the installation of i-doit
-   Be more friendly on a RHEL/CentOS system

### Changed

-   More checks for required binaries

### Fixed

-   Missing chronic on RHEL
-   Parse updates.xml properly for latest i-doit version
-   Fixed broken name of temporary directory

## [0.6][] – 2017-07-24

### Added

-   Get primary IP address on all supported operating systems
-   Install SOAP module for PHP
-   Enable Apache module mod_access_compat under SLES 12 SP2
-   Create the first backup automatically
-   Install "chronic" under SLES

## [0.5][] – 2017-07-13

### Added

-   Support for SUSE Linux Enterprise Server (SLES) 12 SP2
-   Scripts to backup and restore i-doit
-   Dedicated MariaDB user for i-doit
-   Require successful installation of i-doit before deploying scripts

## [0.4][] – 2017-07-12

### Added

-   Deploy cron jobs and an easy-to-use CLI tool for the i-doit controller

## [0.3][] – 2017-07-10

### Added

-   Support for Red Hat Enterprise Linux (RHEL) 7.3
-   Support for CentOS 7.3
-   Soft requirement to use a x86 64 bit OS
-   Question whether to reboot an Ubuntu OS
-   Warning to read the documentation
-   Warning not to edit the built-in configuration
-   Recommend Debian GNU/Linux 9 "stretch"

## [0.2][] – 2017-07-07

### Added

-   Support for Ubuntu Linux 16.10 and 17.04

## 0.1 – 2017-07-07

Initial release

[Unreleased]: https://github.com/i-doit/scripts/compare/0.14...HEAD
[0.14]: https://github.com/i-doit/scripts/compare/0.13...0.14
[0.13]: https://github.com/i-doit/scripts/compare/0.12...0.13
[0.12]: https://github.com/i-doit/scripts/compare/0.11...0.12
[0.11]: https://github.com/i-doit/scripts/compare/0.10...0.11
[0.10]: https://github.com/i-doit/scripts/compare/0.9...0.10
[0.9]: https://github.com/i-doit/scripts/compare/0.8...0.9
[0.8]: https://github.com/i-doit/scripts/compare/0.7...0.8
[0.7]: https://github.com/i-doit/scripts/compare/0.6...0.7
[0.6]: https://github.com/i-doit/scripts/compare/0.5...0.6
[0.5]: https://github.com/i-doit/scripts/compare/0.4...0.5
[0.4]: https://github.com/i-doit/scripts/compare/0.3...0.4
[0.3]: https://github.com/i-doit/scripts/compare/0.2...0.3
[0.2]: https://github.com/i-doit/scripts/compare/0.1...0.2
