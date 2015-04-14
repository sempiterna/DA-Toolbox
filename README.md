DA-Toolbox
=============

DA-Toolbox is a menudriven shell (bash) script to install and update software on DirectAdmin servers:

1. Install PHP modules and extensions
2. Update and Upgrade PHP (including an upgrade to PHP 5.6 on Custombuild 1)
3. Update and Upgrade MySQL
4. Install additional software such as mod_ruid2, Postgress server, Python 2.7 (CentOS 5 and 6), Git, Redis server

This script (for the most part) requires DirectAdmin, Custombuild 1 or 2, CentOS 5, 6 or 7 and Apache. **No other distributions are supported**. RHEL could work, but unfortunately I have no RHEL system available to test with.

I used to work at a company which is hosting thousands of virtual private servers (VPS) and dedicated servers. Every day clients were asking us (support) to install PHP modules or other software, which was a lot of repetitive and time consuming work. I decided that most of this work could be scripted and automated, which lead to me creating this script early 2014. It has been in active use ever since on hundreds of production servers, saving the support department valuable time.

This company I worked for was only rolling out DirectAdmin servers using CentOS 5 and 6 with Custombuild 1, so initially only support for Custombuild 1 was built in. Last month (03/2015) I also added support for Custombuild 2 (including support for 2 simultaneous PHP versions) and CentOS 7. These additions have been extensively tested on my test servers, and should work without fault.

An extensive rollback feature was also added. The script will copy all major configuration files, and restores them if something goes wrong during an installation. It will also log the installation action, so a rollback to the last state (also recursively) can be done using the script menu, or with the rollback.sh script that da-toolbox creates whenever it makes a configuration files backup.

## Usage:

Download `da_toolbox.sh` from this repository, and start with:

`sh da_toolbox.sh`

or 

`chmod 755 da_toolbox.sh`

`./da_toolbox.sh`

By default, this script will store configuration file backups and software downloads to `/usr/local/src/toolbox`. You can change this by editing the `SRCDIR` variable.

This script should be run as root or a user with root privileges. It also works with a menu structure using 2 columns. If it detects that the terminal is not wide enough, it will only show one column. If only one column is shown, some information may not be visible.

This script (for safety reasons) allows for termination with CTRL-C, however it is strongly advised to not terminate the script while it is in the process of installing or updating software. Only do so if you are monitoring the screen output, and you notice that something goes horribly wrong in the process.

Software and PHP module versions can be modified by editing the variables below `Module version names`. It is strongly advised to execute a test installation of the changes using a test server before using it on a production server.

## Extending:

I have tried to make it relatively easy to extend this script with more PHP modules and extensions, and I may add some more info either in this readme file or a separate file on how to extend the script.

For questions, suggestions, or remarks please e-mail me at jeroen@wierda.com :)
