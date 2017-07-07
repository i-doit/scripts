#   i-doit scripts

Useful scripts to maintain i-doit


##  About

[i-doit](https://i-doit.com) is a software application for IT documentation and a CMDB (Configuration Management Database). This application is very useful to collect all your knowledge about the IT infrastructure you are dealing with. i-doit is a Web application and [has an exhausting API](https://kb.i-doit.com/pages/viewpage.action?pageId=37355644) which is very useful to automate your infrastructure.


##  Install i-doit on a GNU/Linux operating system

The script `idoit-install.sh` allows you to easily install the latest version of

*   i-doit pro or
*   i-doit open

on a fresh installation of a GNU/Linux operating system. Supported OSs are:

*   Debian GNU/Linux 9 "Stretch"
*   Debian GNU/Linux 8 "Jessie"
*   Ubuntu Linux 16.04 LTS "Xenial"
*   Ubuntu Linux 16.10 "Yakkety"
*   Ubuntu Linux 17.04 "Zesty"

Before you execute this script you should…

*   Install one of the supported operating systems based on the [requirements mentioned in the i-doit knowledge base](https://kb.i-doit.com/display/en/System+Requirements)
*   Create a backup/snapshot of your system
*   Make sure that the system is allowed to access external Web services, for example package repositories and the i-doit website.

The "rest" can done by the script.

The script includes several steps which are all optional, but essential for running i-doit:

*   Install needed distribution packages
*   Configure PHP
*   Configure Apache Web server
*   Configure MariaDB DBMS
*   Download and install the latest version of i-doit pro or open

All steps are based on information provided by the [i-doit knowledge base](https://kb.i-doit.com/display/en/).

On a fresh installation download the script `idoit-install.sh` and execute it with super-user rights (`root`).

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

Sometimes you need to restart your system so all changes take effect.

As `root`:

~~~ {.bash}
systemctl reboot
~~~

As non-`root`:

~~~ {.bash}
sudo systemctl reboot
~~~


### Who should use this script?

You should install i-doit with this script if you agree with one or more of the following statements:

1)  "I need a stable instance of i-doit with a good performance installed on a recommended operating system."
2)  "I am unsure how to maintain a GNU/Linux operating system."
3)  "I do not have the time to setup i-doit."


### Who should not use this script?

You **should not** install i-doit with this script if you agree with one or more of the following statements:

1) "I am an experienced GNU/Linux system administrator."
2) "i-doit will not be the only application on this system."
3) "I have special requirements to run i-doit."


### What to do next?

There are several steps you still need to do by yourself:

1)  [Install your license (only pro version)](https://kb.i-doit.com/display/en/Install+License)
2)  [Configure cron jobs](https://kb.i-doit.com/pages/viewpage.action?pageId=37355566)
3)  [Configure backups (and test it!)](https://kb.i-doit.com/display/en/Backup+and+Recovery)
4)  Document your IT (obviously ;-))


##  Contribute & Support

Please, report any issues to [our issue tracker](https://github.com/bheisig/i-doit-scripts/issues). Pull requests are very welcomed.


##  Copyright & License

Copyright (C) 2017 [Benjamin Heisig](https://benjamin.heisig.name/)

Licensed under the [GNU Affero GPL version 3 or later (AGPLv3+)](https://gnu.org/licenses/agpl.html). This is free software: you are free to change and redistribute it. There is NO WARRANTY, to the extent permitted by law.
