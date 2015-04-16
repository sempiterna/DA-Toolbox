#!/bin/bash
# ------------------------------------------------------------------------
# Script: da_toolbox.sh
# Author: Jeroen Wierda (jeroen@wierda.com)
# Version: 0.94 (15/04/15)
# Copyright (C) 2014, 2015
#
# Script to install/upgrade software, php modules and extensions. 
# DirectAdmin is required for most of these installations.
# This script assumes: Apache 2.x, DA Custombuild, CentOS 5,6,7.
#
# This script can be downloaded from:
# https://github.com/sempiterna/DA-Toolbox
#
# Menu structure partially used from:
# http://bash.cyberciti.biz/guide/Menu_driven_scripts
# 
# ------------------------------------------------------------------------
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------

## Module version names
IMAGICK=imagick-3.1.2
PDFLIBCOM=PDFlib-Lite-7.0.5p3
PDFLIBPECL=pdflib-3.0.4
MAILPARSEPECL=mailparse-2.1.6
MEMCACHEPECL=memcache-2.2.7
MEMCACHEDPECL=memcached-2.2.0
LIBMEMCACHED=libmemcached-1.0.18 #If this is edited, also edit LIBMEMCACHEDURL
APCPECL=APC-3.1.9
ZENDOPCACHEPECL=zendopcache-7.0.4
REDISPECL=redis-2.2.7
MR2FILE=mod_ruid2-0.9.8.tar.bz2
REDISFILE=redis-2.8.19
GITFILE=master
PYTHON=Python-2.7.9 #If this is edited, also edit PYTHONURL
PHPIMAP=imap-2007f
SSH2PECL=ssh2-0.11.3
ICU=icu4c-54_1-src #If this is edited, also edit ICUURL
PSREPO=pgdg-redhat94-9.4-1.noarch #postgres repo version. If this is edited, also edit PSREPOURL
PSVER=9.4 #postgres version
	
## url locations
PDFLIBURL=http://www.pdflib.com/binaries/PDFlib/705/
PECLURL=http://pecl.php.net/get/
MOD_RUID_URL=http://downloads.sourceforge.net/project/mod-ruid/mod_ruid2/
REDISURL=http://download.redis.io/releases/
GITURL=https://github.com/git/git/archive/
PYTHONURL=http://python.org/ftp/python/2.7.9/
PHPIMAPURL=ftp://ftp.cac.washington.edu/imap/
LIBMEMCACHEDURL=https://launchpad.net/libmemcached/1.0/1.0.18/+download/
ICUURL=http://download.icu-project.org/files/icu4c/54.1/
PSREPOURL=http://yum.postgresql.org/9.4/redhat

## Menu options
MHEADER="PHP Module Installations"
MITEM_1=" 1. Imagick"
MITEM_2=" 2. PDFlib"
MITEM_3=" 3. Mailparse"
MITEM_4=" 4. Memcache(d)"
MITEM_5=" 5. APC"
MITEM_6=" 6. XSL Extension"
MITEM_7=" 7. PHP Redis"
MITEM_8=" 8. Zend OPcache"
MITEM_9=" 9. IMAP Extension"
MITEM_10="10. SSH2"
MITEM_11="11. LDAP Extension"
MITEM_12="12. Tidy Extension"
MITEM_13="13. Intl Extension"

MHEADER2="Other Installations"
MITEM_100="100. mod_ruid2"
MITEM_101="101. Redis server"
MITEM_102="102. GIT"
MITEM_103="103. Python 2.7 (as 2nd)"
MITEM_104="104. Postgres SQL"

MHEADER3="PHP updates (Current Version: $PHP_VER)"
MITEM_200="200. PHP update (minor update)"
MITEM_201="201. PHP upgrade to 5.3"
MITEM_202="202. PHP upgrade to 5.4"
MITEM_203="203. PHP upgrade to 5.5"
MITEM_204="204. PHP upgrade to 5.6"

MHEADER4="Other updates"
MITEM_300="300. MySQL (minor version update)"
MITEM_301="301. MySQL upgrade to 5.5"
MITEM_302="302. MySQL upgrade to 5.6"

MEXIT="Type x to exit the script"

##DA
DA_OPTIONS=/usr/local/directadmin/custombuild/options.conf
DA_CUSTOMBUILD=/usr/local/directadmin/custombuild

## Other vars
RED='\033[0;41;30m'
STD='\033[0;0;39m'
PASS=0
SRCDIR=/usr/local/src/toolbox
CBITS="("`uname -i`")"
OS_TYPE=`cat /etc/redhat-release |sed s/\ release.*//I |sed s/\ .*//`
OS_VER=`cat /etc/redhat-release |sed s/.*release\ //I |sed s/\ .*//`
CENTOS_V="$OS_TYPE $OS_VER $CBITS"
MEMORY=`free -m | awk '{ print "Total: " $2"MB Free: " $4"MB" }' |head -2 |tail -1`
CUSTOMBUILD_VER=`cat /usr/local/directadmin/custombuild/options.conf |grep custombuild= |cut -d '=' -f2`
REBUILD=""
PHP_TIMEZONE="Europe\/Amsterdam"

## value yes/no. Yes if you run both the cli as well as cgi versions of PHP (CB1). PHP will be compiled twice if yes. Not many people will use this.
PHP_CLI_CGI="no"

## author info
AUTHOR="DA_Toolbox version: 0.94 (15/04/15)\nAuthor: Jeroen Wierda (jeroen@wierda.com)\nCopyright (C) 2014, 1015 (GNU GPLv3)"

## Check requirements
if [ ${CUSTOMBUILD_VER:0:1} == 2 ]; then
	MITEM_204_CB2="$MITEM_204"
	MYSQL_CHECK=`mysql -V |cut -d" " -f6 |tr -d  , |grep -i mariadb`
	if [ "$MYSQL_CHECK" != "" ]; then
		##Switch items concerning MySQL for MariaDB
		MITEM_300="300. MySQL (MariaDB)(minor update)"
		MITEM_301="301. MySQL (MariaDB) upgrade to 10.0"
		MARIADB=1
		unset MITEM_302
	fi
	COMMENTR=""
else
	MITEM_204_CB2="$MITEM_204 (!)"
	COMMENTR="\n(!) You are using custombuild 1.x. While not officially supported by custombuild 1.2, this DA_Toolbox script allows for a PHP upgrade to version 5.6 (menu option 204)."
fi

if ! rpm -qa | grep -q "autoconf"; then
	yum -y install autoconf
fi

if ! rpm -qa | grep -q "^bc"; then
	yum -y install bc
fi

if ! rpm -qa | grep -q "libtool"; then
	yum -y install libtool
fi

if ! [ -d $SRCDIR ]; then
	mkdir -p $SRCDIR
fi

## CB2 (with ioncube and/or zend) has a file called 10-directadmin.ini which is loaded with PHP and contains the extension_dir and zend extensions
if [ -f /usr/local/lib/php.conf.d/10-directadmin.ini ]; then
	ALT_INI=1
	ALT_INI_FILE=/usr/local/lib/php.conf.d/10-directadmin.ini
	INI_FILE=/usr/local/lib/php.conf.d/10-directadmin.ini
else
	ALT_INI=0
	INI_FILE=/usr/local/lib/php.conf.d/10-directadmin.ini
fi

if [ -f /usr/local/etc/php5/cgi/php.ini ]; then
	PHP5CGI=/usr/local/etc/php5/cgi/php.ini
else
	PHP5CGI=""
fi

## Copy config files for safekeeping (maybe add type to find the correct backup lateron)
function initcopy {
	ALT_INI=0
	NOW_DATE_INIT=`date +'%m%d%y_%H%M%S'`
	#NOW_DATE_INIT=`date +'%s'`
	if ! [ -a $SRCDIR/$NOW_DATE_INIT ]; then 
		mkdir $SRCDIR/$NOW_DATE_INIT
	fi
	if [ -f $SRCDIR/lastaction.txt ]; then
		mv $SRCDIR/lastaction.txt $SRCDIR/$NOW_DATE_INIT/lastaction.txt.prev
	fi
	touch $SRCDIR/lastaction.txt
	cd $SRCDIR/$NOW_DATE_INIT
	touch rollback.sh && chmod 755 rollback.sh
	echo "#!/bin/bash" >> rollback.sh
	if ! [ -a $SRCDIR/$NOW_DATE_INIT/configs ]; then 
		mkdir $SRCDIR/$NOW_DATE_INIT/configs
	fi
	cd $SRCDIR/$NOW_DATE_INIT/configs
	cp -p /usr/local/lib/php.ini php.ini.cli
	echo "cp -p php.ini.cli /usr/local/lib/php.ini" >> rollback.sh
	if [ -n "$PHP5CGI" ]; then
		cp -p /usr/local/etc/php5/cgi/php.ini php.ini.cgi
		echo "cp -p php.ini.cgi /usr/local/etc/php5/cgi/php.ini" >> rollback.sh
	fi
	echo "cd $SRCDIR/$NOW_DATE_INIT/configs" >> ../rollback.sh
	cp -p $DA_CUSTOMBUILD/options.conf options.conf
	echo "cp -p options.conf $DA_CUSTOMBUILD/options.conf" >> ../rollback.sh
	cp -p /etc/httpd/conf/httpd.conf httpd.conf
	echo "cp -p httpd.conf /etc/httpd/conf/httpd.conf" >> ../rollback.sh
	cp -p /etc/httpd/conf/extra/httpd-directories.conf httpd-directories.conf
	echo "cp -p httpd-directories.conf /etc/httpd/conf/extra/httpd-directories.conf" >> ../rollback.sh
	cp -p /etc/httpd/conf/extra/httpd-phpmodules.conf httpd-phpmodules.conf
	echo "cp -p httpd-phpmodules.conf /etc/httpd/conf/extra/httpd-phpmodules.conf" >> ../rollback.sh
	if [ -d $DA_CUSTOMBUILD/custom/ap2/conf ]; then
		cp -p $DA_CUSTOMBUILD/custom/ap2/conf/httpd.conf httpd.conf.ap2
		cp -p $DA_CUSTOMBUILD/custom/ap2/conf/extra/httpd-directories-old.conf httpd-directories-old.conf.ap2
		echo "cp -p httpd.conf.ap2 $DA_CUSTOMBUILD/custom/ap2/conf/httpd.conf" >> ../rollback.sh
		echo "cp -p httpd-directories-old.conf.ap2 $DA_CUSTOMBUILD/custom/ap2/conf/extra/httpd-directories-old.conf" >> ../rollback.sh
	fi
	if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
		if [ -d $DA_CUSTOMBUILD/custom ]; then
			cp -p $DA_CUSTOMBUILD/custom/ap2/configure.php5 configure.php5
			cp -p $DA_CUSTOMBUILD/custom/suphp/configure.php5 configure.php5.suphp
			echo "cp -p configure.php5 $DA_CUSTOMBUILD/custom/ap2/configure.php5" >> ../rollback.sh
			echo "cp -p configure.php5.suphp $DA_CUSTOMBUILD/custom/suphp/configure.php5" >> ../rollback.sh
		fi
	else
		CONF_VER="53 54 55 56"
		if [ -d $DA_CUSTOMBUILD/custom ]; then
			CB2_PHP_CONF="ap2 suphp fastcgi litespeed fpm"
			for phpconf in $CB2_PHP_CONF
			do
				for confver in $CONF_VER
				do
					cp -p $DA_CUSTOMBUILD/custom/$phpconf/configure.php$confver configure.php$confver.$phpconf
					echo "cp -p configure.php$confver.$phpconf $DA_CUSTOMBUILD/custom/$phpconf/configure.php$confver" >> ../rollback.sh
				done
			done
		fi
		if [ -f /usr/local/lib/php.conf.d/10-directadmin.ini ]; then
			## new location for DA installed items such as zend guard and ioncube
			cp -p /usr/local/lib/php.conf.d/10-directadmin.ini .
			echo "cp -p 10-directadmin.ini /usr/local/lib/php.conf.d/10-directadmin.ini" >> ../rollback.sh
		fi
		
		for confver in $CONF_VER
		do
			if [ -f /usr/local/php$confver/lib/php.conf.d/10-directadmin.ini ]; then
				cp -p /usr/local/php$confver/lib/php.conf.d/10-directadmin.ini 10-directadmin.ini.php$confver
				echo "cp -p 10-directadmin.ini.php$confver /usr/local/php$confver/lib/php.conf.d/10-directadmin.ini" >> ../rollback.sh
			fi
			if [ -f /usr/local/php$confver/lib/php.ini ]; then
				cp -p /usr/local/php$confver/lib/php.ini php.ini.php$confver
				echo "cp -p php.ini.php$confver /usr/local/php$confver/lib/php.ini" >> ../rollback.sh
			fi
		done
		unset CONF_VER CB2_PHP_CONF
	fi
	if [ ${OS_VER:0:1} \< "7" ]; then
		echo "service httpd restart" >> ../rollback.sh
	else
		echo "systemctl restart httpd" >> ../rollback.sh
	fi
	echo "echo \"If you are rolling back due to an extension that was built into PHP itself via config flags (for example XSL, LDAP, IMAP, Tidy, Intl), or after a PHP upgrade, then you will need to rebuild PHP. This can be done by executing '/usr/local/directadmin/custombuild/build php n' or by selecting option 200 in Da_toolbox.\"" >> ../rollback.sh
	echo "exit 0" >> ../rollback.sh
}

cd $SRCDIR

function rollback {
	cp -p $SRCDIR/$NOW_DATE_INIT/configs/php.ini.cli /usr/local/lib/php.ini
	if [ -n "$PHP5CGI" ]; then
		cp -p $SRCDIR/$NOW_DATE_INIT/configs/php.ini.cgi /usr/local/etc/php5/cgi/php.ini
	fi
	cp -p $SRCDIR/$NOW_DATE_INIT/configs/options.conf $DA_CUSTOMBUILD/options.conf
	if [ -f $SRCDIR/$NOW_DATE_INIT/configs/httpd.conf ]; then
		cp -p $SRCDIR/$NOW_DATE_INIT/configs/httpd.conf /etc/httpd/conf/httpd.conf
		cp -p $SRCDIR/$NOW_DATE_INIT/configs/httpd.conf.ap2 $DA_CUSTOMBUILD/custom/ap2/conf/httpd.conf
		cp $SRCDIR/$NOW_DATE_INIT/configs/httpd-directories.conf /etc/httpd/conf/extra/httpd-directories.conf
		cp $SRCDIR/$NOW_DATE_INIT/configs/httpd-phpmodules.conf /etc/httpd/conf/extra/httpd-phpmodules.conf
		cp -p $SRCDIR/$NOW_DATE_INIT/configs/httpd-directories-old.conf.ap2 $DA_CUSTOMBUILD/custom/ap2/conf/extra/httpd-directories-old.conf
	fi
	if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
		if [ -d $DA_CUSTOMBUILD/custom ]; then
			cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php5 $DA_CUSTOMBUILD/custom/ap2/configure.php5
			cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php5.suphp $DA_CUSTOMBUILD/custom/suphp/configure.php5
		fi
	else
		if [ -d $DA_CUSTOMBUILD/custom ]; then
			CB2_PHP_CONF="ap2 suphp fastcgi litespeed fpm"
			for phpconf in $CB2_PHP_CONF
			do
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php53.$phpconf $DA_CUSTOMBUILD/custom/$phpconf/configure.php53
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php54.$phpconf $DA_CUSTOMBUILD/custom/$phpconf/configure.php54
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php55.$phpconf $DA_CUSTOMBUILD/custom/$phpconf/configure.php55
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/configure.php56.$phpconf $DA_CUSTOMBUILD/custom/$phpconf/configure.php56
			done
		fi
		if [ -f /usr/local/lib/php.conf.d/10-directadmin.ini ]; then
			## new location for DA installed items such as zend guard and ioncube
			cp -p $SRCDIR/$NOW_DATE_INIT/configs/10-directadmin.ini /usr/local/lib/php.conf.d/
		fi
		
		CONF_VER="53 54 55 56"
		for confver in $CONF_VER
		do
			if [ -f /usr/local/php$confver/lib/php.conf.d/10-directadmin.ini ]; then
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/10-directadmin.ini.php$confver /usr/local/php$confver/lib/php.conf.d/10-directadmin.ini
			fi
			if [ -f /usr/local/php$confver/lib/php.ini ]; then
				cp -p $SRCDIR/$NOW_DATE_INIT/configs/php.ini.php$confver /usr/local/php$confver/lib/php.ini
			fi
		done
		unset CONF_VER CB2_PHP_CONF
	fi
	##Make sure that after rollback is completed, the previous rollback option is displayed
	if [ -f $SRCDIR/$NOW_DATE_INIT/lastaction.txt.prev ]; then
		mv $SRCDIR/$NOW_DATE_INIT/lastaction.txt.prev $SRCDIR/lastaction.txt
	else
		rm -f $SRCDIR/lastaction.txt
	fi
	unset L_EPOCH L_ACTION L_DIR L_MENU
	if [ "$MANUAL_ROLLBACK" == "1" ]; then
		service_management "service" "restart" "httpd"
		COMMENTR="Roll back has completed.\nIf you were rolling back due to an extension that was built into PHP itself via config flags (for example XSL, LDAP, IMAP, Tidy, Intl), or after a PHP upgrade, then you will need to rebuild PHP. This can be done by executing '/usr/local/directadmin/custombuild/build php n' or by selecting option 200 (PHP Update)."
	else
		echo "Rollback completed!";
	fi
}

function rollback_manual {
	if [ -f $SRCDIR/lastaction.txt ] && [ -s $SRCDIR/lastaction.txt ]; then
		if [ -d $SRCDIR/$L_DIR ]; then
			clear
			read -p "You are about to roll back the last stored action '$L_ACTION' from date '$L_EPOCH'. This will not remove software, but only restores all backed up config files.
			
Make sure that you have not made any other updates since this restore point was created.
			
Are you sure you wish to proceed? (y/n): " RESP
			if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
				MANUAL_ROLLBACK=1
				NOW_DATE_INIT=$L_DIR
				rollback
			else
				COMMENTR="Rollback aborted."
				return 1
			fi
		fi
	fi
}

function last_action {
	EPOCH=`date +%s`
	if [ "$LOG_ACTION" ]; then
		echo "$EPOCH:$LOG_ACTION:$NOW_DATE_INIT" >> $SRCDIR/lastaction.txt
	fi
}

pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

function service_management {
	if [ "$1" == "service" ] && ([ "$2" == "start" ]|| [ "$2" == "restart" ] || [ "$2" == "stop" ] || [ "$2" == "reload" ]); then
		if [ ${OS_VER:0:1} \< "7" ]; then
			/sbin/service $3 $2
		else
			/usr/bin/systemctl $2 $3
		fi
	elif [ "$1" == "chkconfig" ] && ([ "$2" == "on" ] || [ "$2" == "off" ]); then
		if [ ${OS_VER:0:1} \< "7" ]; then
			/sbin/chkconfig $3 $2
		else
			if [ "$2" == "on" ]; then
				/usr/bin/systemctl enable $3
			elif [ "$2" == "off" ]; then
				/usr/bin/systemctl disable $3
			fi
		fi
	fi
}

function customfolder {
	##check if custom directory and/or required files exists
	if [ ! -d "$DA_CUSTOMBUILD/custom" ]; then
		mkdir $DA_CUSTOMBUILD/custom			
	fi
	ALL_CUSTOM="ap2 suphp fastcgi litespeed fpm"
	for CUSTOM in $ALL_CUSTOM
	do
		if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
			if [ $CUSTOM == "fastcgi" ] || [ $CUSTOM == "litespeed" ] || [ $CUSTOM == "fpm" ]; then
				continue
			fi
			if [ ! -d "$DA_CUSTOMBUILD/custom/$CUSTOM" ]; then
				mkdir $DA_CUSTOMBUILD/custom/$CUSTOM
				cp -p $DA_CUSTOMBUILD/configure/$CUSTOM/configure.php5 $DA_CUSTOMBUILD/custom/$CUSTOM
			elif [ ! -f "$DA_CUSTOMBUILD/custom/$CUSTOM/configure.php5" ]; then
				cp -p $DA_CUSTOMBUILD/configure/$CUSTOM/configure.php5 $DA_CUSTOMBUILD/custom/$CUSTOM
			fi
		else
			if [ ! -d "$DA_CUSTOMBUILD/custom/$CUSTOM" ]; then
				mkdir $DA_CUSTOMBUILD/custom/$CUSTOM
				cp -p $DA_CUSTOMBUILD/configure/$CUSTOM/configure.php5* $DA_CUSTOMBUILD/custom/$CUSTOM
			else
				CONF_VER="53 54 55 56"
				for confver in $CONF_VER
				do
					if [ ! -f "$DA_CUSTOMBUILD/custom/$CUSTOM/configure.php$confver" ]; then
						cp -p $DA_CUSTOMBUILD/configure/$CUSTOM/configure.php$confver $DA_CUSTOMBUILD/custom/$CUSTOM
					fi
				done
			fi
			unset CONF_VER ALL_CUSTOM
		fi
	done
}

function error_handler {
	if ! [ "$?" = "0" ]; then
		echo $1
		if [ "$2" == "rollback" ]; then
			rollback
		fi
		exit 1
	fi
}

function which_method {
	if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
		php_build_extension_a
	else
		php_build_extension_b
	fi
}

function get_module_status {
	VAR_I=""
	for iniloop in $INI_LOOP
	do
		if grep -qi "^$2=$1" $iniloop; then
			if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
			VAR_I="(installed)";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/lib/php.ini" ]; then
			VAR_I="1";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini" ]; then
			VAR_Ib="1";
			fi
			MOD="$1";
		fi
	done
	
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP != "no" ]; then
		if [ "$VAR_I" == "1" ] && [ "$VAR_Ib" == "1" ]; then
			VAR_I="(installed:_both)"
		elif [ "$VAR_I" != "1" ] && [ "$VAR_Ib" == "1" ]; then
			VAR_I="(installed:_PHP2)"
		elif [ "$VAR_I" == "1" ] && [ "$VAR_Ib" != "1" ]; then
			VAR_I="(installed:_PHP1)"
		elif [ "$VAR_I" != "1" ] && [ "$VAR_Ib" != "1" ]; then
			VAR_I=""
		fi
	fi
	echo "$VAR_I,$MOD"
}

function get_module_status_return(){
	echo `echo $1 |cut -d',' -f$2`
}

function get_extension_status {
	if [ "$1" == "php" ]; then
		if php -m |grep -iq $2; then 
			VAR_I="$3"
		fi
	elif [ "$1" == "grep" ]; then
		if grep -qi "$2" "$4"; then
			VAR_I="$3"
		fi
	elif [ "$1" == "rpm" ]; then
		if rpm -qa |grep -iq "$2"; then
			VAR_I="$3"
		fi
	elif [ "$1" == "file" ]; then
		if [ -f $2 ]; then
			VAR_I="$3"
		fi
	elif [ "$1" == "apache" ]; then
		if httpd -M |grep -iq $2; then
			VAR_I="$3"
		fi
	fi
	echo $VAR_I
}

function ask_rpm_remove {
	if [ "$(ls -A $DA_CUSTOMBUILD/mysql)" ]; then
		clear
		read -p "Force redownload of MySQL/MariaDB rpm's? Pressing y will remove all previously downloaded rpm's from the $DA_CUSTOMBUILD/mysql directory. (y/n) " RESP
		if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
			rm -Rf $DA_CUSTOMBUILD/mysql/*.rpm
		fi
	fi
}

git() {
	if [ -f /usr/local/bin/git ]; then
		echo -e "GIT seems to be already installed.\n";
	else
		yum -y install expat-devel gettext-devel unzip
		
		error_handler "Error during yum installation: script will exit now."
		
		cd $SRCDIR

		wget --no-check-certificate $GITURL$GITFILE.zip

		error_handler "Error during downloading of GIT source: script will exit now."
		
		unzip $GITFILE

		cd git-master
		make configure
		./configure --prefix=/usr/local
		make all && make install

		error_handler "Error during compilation of GIT cache."
		
		COMMENTR="GIT is successfully installed.\n";
		echo -e $COMMENTR
	fi
	pause

}
 
redis() {
	if [ -f /etc/redis/redis.conf ] || [ -f /etc/redis.conf ]; then
		echo -e "The redis server seems to be already installed.\n";
	else
		if ! rpm -qa | grep telnet; then
			yum -y install telnet
			error_handler "Error during yum installation: script will exit now."
		fi

		## check if we are running CentOS 7, and if so, install using the epel repository. Manual install would also be possible, but i have not yet found a systemd script for redis.
		if [ ${OS_VER:0:1} \< "7" ]; then
			cd $SRCDIR
			
			CBITS=`uname -i`
			if [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
				##prevent zmalloc errors install libc6-dev-i386
				yum -y install glibc-devel
				error_handler "Error during yum installation: script will exit now."
				wget --no-check-certificate https://github.com/antirez/redis/archive/2.4.18.tar.gz
				error_handler "Error during downloading of the redis server: script will exit now."
				tar -zxvf 2.4.18.tar.gz
				cd redis-2.4.18
				make distclean && make 32bit && make install
				COMMENTR="\nDue to this OS being 32bit, Redis version 2.4.18 is installed.\n"
			else
				wget $REDISURL$REDISFILE.tar.gz
				error_handler "Error during downloading of the redis server: script will exit now."
				tar -zxvf $REDISFILE.tar.gz
				cd $REDISFILE
				make distclean && make && make install
			fi

			error_handler "Error during compilation of Redis server."
			
			mkdir /etc/redis /var/lib/redis
			sed -e "s/^daemonize no$/daemonize yes/" -e "s/^dir \.\//dir \/var\/lib\/redis\//" -e "s/^loglevel debug$/loglevel notice/" -e "s/^logfile stdout$/logfile \/var\/log\/redis.log/" redis.conf > /etc/redis/redis.conf
			 
			cd $SRCDIR
			 
			wget --no-check-certificate https://gist.githubusercontent.com/paulrosania/257849/raw/9f1e627e0b7dbe68882fa2b7bdb1b2b263522004/redis-server

			if ! [ "$?" = "0" ]; then
				echo -e "Error grabbing the Redis server init script. The redis server is successfully installed, but has to be started manually until an init script exists to daemonize it. The service name is 'redis-server'. The github location of the init script: https://gist.github.com/paulrosania/257849 \n"
			else
			
				sed -i "s/usr\/local\/sbin\/redis/usr\/local\/bin\/redis/" redis-server

				chmod u+x redis-server
				mv redis-server /etc/init.d
				/sbin/chkconfig --add redis-server
				/sbin/chkconfig --level 345 redis-server on
				/sbin/service redis-server start
				
				COMMENTR="The Redis server is successfully installed and daemonized. The service name is 'redis-server'.$COMMENTR\n"
				echo -e "$COMMENTR"
			fi
		elif [ ${OS_VER:0:1} == "7" ]; then
			REPO_URL=http://dl.fedoraproject.org/pub/epel/7/x86_64/e
			YUM_REPO=epel-release-7-5.noarch.rpm
			REPO_URL_C=$REPO_URL/$YUM_REPO
			cd $SRCDIR
			wget $REPO_URL_C
			error_handler "Error during downloading of the EPEL YUM repo: script will exit now."
			rpm -Uvh $YUM_REPO
			yum -y install redis
			
			error_handler "Error during yum installation: script will exit now."
			
			service_management "chkconfig" "on" "redis"
			service_management "service" "start" "redis"
			
			error_handler "Error during Redis start-up: script will exit now."
			
			COMMENTR="The Redis server is successfully installed and daemonized. The service name is 'redis'.\n"
			echo -e "$COMMENTR"
		fi
	fi
	pause
}				
				
python_27() {
	PY_EXT=.tgz

	if [ -f /usr/local/bin/python2.7 ]; then
		echo -e "Python 2.7 is already installed.\n";
	elif [ ${OS_VER:0:1} == "7" ]; then
		COMMENTR="CentOS 7 already has Python 2.7 installed by default.";
		return 1
	else
		yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel gcc gcc++

		error_handler "Error during yum installation: script will exit now."
		
		cd $SRCDIR

		wget --no-check-certificate $PYTHONURL$PYTHON$PY_EXT
		
		error_handler "Error during downloading of Python 2.7: script will exit now."
		
		tar -zxvf $PYTHON$PY_EXT
		cd $PYTHON

		./configure --prefix=/usr/local --enable-shared
		make && make altinstall
		
		error_handler "Error during compilation of Python 2.7."
		
		ln -s /usr/local/bin/python2.7 /usr/local/bin/python

		##install python distribute
		if grep -q "/usr/local/lib" "/etc/ld.so.conf"; then
			echo -e "/usr/local/lib is listed in /etc/ld.so.conf";
			ldconfig
		else
			echo -e "/usr/local/lib is no listed in /etc/ld.so.conf, so going to add";
			echo "/usr/local/lib" >> /etc/ld.so.conf
			ldconfig
		fi

		cd $SRCDIR
		wget --no-check-certificate http://pypi.python.org/packages/source/d/distribute/distribute-0.6.49.tar.gz 
		tar xf distribute-0.6.49.tar.gz
		cd distribute-0.6.49
		python2.7 setup.py install
		easy_install-2.7 requests
	
		COMMENTR="Python 2.7 is successfully installed, and can be called from /usr/local/bin/python and /usr/local/bin/python2.7. The distribute package is also installed, and can be called with easy_install-2.7."
	fi
	pause	
}

postgres(){
	CBITS=`uname -i`
	PS_VER_DOT=${PSVER//./}

	cd $SRCDIR

	read -p "Do you wish to install Postgres server. (y/n) " RESP
	if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
		if ! rpm -qa |grep -iq "postgres.*-server"; then
			if [ ${OS_VER:0:1} == "5" ]; then
				if [ $CBITS == "x86_64" ]; then
					YUM_REPO=$PSREPO.rpm
					PSARCH=rhel-5-x86_64
					REPO_URL_C=$PSREPOURL/$PSARCH/$YUM_REPO
				elif [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
					YUM_REPO=$PSREPO.rpm
					PSARCH=rhel-5-i386
					REPO_URL_C=$PSREPOURL/$PSARCH/$YUM_REPO
				fi
			elif [ ${OS_VER:0:1} == "6" ]; then
				if [ $CBITS == "x86_64" ]; then
					YUM_REPO=$PSREPO.rpm
					PSARCH=rhel-6-x86_64
					REPO_URL_C=$PSREPOURL/$PSARCH/$YUM_REPO
				elif [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
					YUM_REPO=$PSREPO.rpm
					PSARCH=rhel-6-i386
					REPO_URL_C=$PSREPOURL/$PSARCH/$YUM_REPO
				fi
			elif [ ${OS_VER:0:1} == "7" ]; then
					YUM_REPO=$PSREPO.rpm
					PSARCH=rhel-7-x86_64
					REPO_URL_C=$PSREPOURL/$PSARCH/$YUM_REPO
			fi
			
			wget $REPO_URL_C
			error_handler "Error during download of the Postgres repo: script will exit now."
			
			rpm -ivh $YUM_REPO
			error_handler "Error during installation of the Postgres repo: script will exit now."
			
			yum -y install postgresql$PS_VER_DOT-server postgresql$PS_VER_DOT-devel
			error_handler "Error during yum installation: script will exit now."
			
			##remove rpm
			rpm -e $PSREPO
			
			/usr/pgsql-$PSVER/bin/postgresql$PS_VER_DOT-setup initdb
			
			service_management "chkconfig" "on" "postgresql-$PSVER"
			
			service_management "service" "start" "postgresql-$PSVER"
			
			error_handler "Error during startup of postgres: script will exit now."
			
			echo -e "\nA superuser called da_admin will be created now. Type the password for it below:\n\n"
			su postgres -c "createuser -P -s -e da_admin"
			
			mv /var/lib/pgsql/$PSVER/data/pg_hba.conf /var/lib/pgsql/$PSVER/data/pg_hba.conf.ori
			touch /var/lib/pgsql/$PSVER/data/pg_hba.conf
			chown postgres:postgres /var/lib/pgsql/$PSVER/data/pg_hba.conf
			echo "local   all             all                                     peer" >> /var/lib/pgsql/$PSVER/data/pg_hba.conf
			echo "host    all             all             127.0.0.1/32            md5" >> /var/lib/pgsql/$PSVER/data/pg_hba.conf
			echo "host    all             all             ::1/128                 md5" >> /var/lib/pgsql/$PSVER/data/pg_hba.conf
			echo "host    all             all             0.0.0.0 255.255.255.255 reject" >> /var/lib/pgsql/$PSVER/data/pg_hba.conf

			service_management "service" "restart" "postgresql-$PSVER"
			
			COMMENTRA="Postgres server is successfully installed. The service name is 'postgresql-$PSVER'. A superuser was created with username 'da_admin'.\n\n"
		else
		
		echo -e "\n\nPostgres server seems to be installed already.\n\n"
		
		fi
	fi
	
	if ! [ -d /var/www/html/phpPgAdmin ]; then
	
		read -p "Do you wish to install phpPgAdmin? If yes, it will be installed in /var/www/html/phpPgAdmin. (y/n) " RESP
		if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
		echo -e "\nphppgadmin will be installed now in /var/www/html\n\n"
		
			cd /var/www/html
			wget --no-check-certificate -O master.zip https://github.com/phppgadmin/phppgadmin/archive/master.zip
			
			unzip master.zip
			
			mv phppgadmin-master phpPgAdmin
			chown -R webapps:webapps phpPgAdmin
			cd /var/www/html/phpPgAdmin/conf
			mv config.inc.php-dist config.inc.php
			
			sed -i.bak "s/\[0\]\['host'\] = '.*';/\[0\]\['host'\] = 'localhost';/" config.inc.php
			
			COMMENTRB="phpPgAdmin was installed in /var/www/html/phpPgAdmin.\n\n"
		fi
	else
		echo -e "phpPgAdmin seems to be installed already. Skipping this optional step.\n"
	fi
	
	read -p "Do you wish to rebuild PHP with postgres support? (y/n) " RESP
	if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
		if ! php -m |grep -iq pgsql; then
			i_postgres_php
		else
			echo -e "\n\nThe Postgres PHP module is already loaded.\n\n";
		fi
	fi
	
	COMMENTR="$COMMENTRA$COMMENTRB$COMMENTR"
	unset COMMENTRA COMMENTRB
	pause
}

i_postgres_php(){
	PHP_EXT=1
	EXT_NAME=with-pgsql=\\/usr\\/pgsql-$PSVER
	EXT_NAME2=pgsql
	
	if php -m |grep -i -q $EXT_NAME2 && /usr/local/php$CB2_2PHP_SHORT/bin/php |grep -i -q $EXT_NAME2; then
		echo -e "$EXT_NAME2 seems to be installed already!\n";
	elif php -m |grep -i -q $EXT_NAME2 && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "$PECL_NAME seems to be installed already!\n";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension

		## Add extension and build PHP
		php_build_extension_a
	fi
}

i_imagick(){
	PECL_NAME=Imagick
	PECL_EXT=.tgz
	PECL_FILENAME=$IMAGICK
	PECL_SO=imagick.so
	EXTENSIONTYPE=regular

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module
		if ! rpm -qa | grep ImageMagick-devel; then
			yum -y install ImageMagick ImageMagick-devel

			error_handler "Error during yum installation: script will exit now."
			
		else
			echo -e "ImageMagick software was already installed. Continuing to the PHP module.";
		fi
		##execute php_generic
		php_generic;
	fi
	pause
}
 
i_pdflib(){
	PECL_NAME=PDFlib
	PECL_EXT=.tgz
	PECL_FILENAME=$PDFLIBPECL
	PECL_SO=pdf.so
	EXTENSIONTYPE=regular

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module
		cd $SRCDIR
		wget $PDFLIBURL$PDFLIBCOM.tar.gz

		error_handler "Error during downloading of PDFlib: script will exit now."

		tar zxvf $PDFLIBCOM.tar.gz && cd $PDFLIBCOM
		./configure
		make && make install

		error_handler "Error during compilation PDFlib."
		
		##execute php_generic
		php_generic;
	fi
	pause
}

i_mailparse(){
	PECL_NAME=Mailparse
	PECL_EXT=.tgz
	PECL_FILENAME=$MAILPARSEPECL
	PECL_SO=mailparse.so
	EXTENSIONTYPE=regular

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module

		##execute php_generic
		php_generic;
	fi
	pause
}

i_memcache(){
	PECL_NAME=Memcache
	PECL_EXT=.tgz
	PECL_FILENAME=$MEMCACHEPECL
	PECL_SO=memcache.so
	EXTENSIONTYPE=regular
	#CONFIGUREFLAG="--disable-memcached-sasl"

	read -p "Do you want to install the memcached server? (y/n) " RESP
	if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
		if ! rpm -qa | grep memcached; then
			SPECIFICS="\nConfiguration options for memcached can be found in /etc/sysconfig/memcached."
			if [ ${OS_VER:0:1} == "5" ]; then
				CBITS=`uname -i`
				#REPO_URL=http://pkgs.repoforge.org/rpmforge-release/
				REPO_URL=http://mirrors.kernel.org/fedora-epel/5/

				if [ $CBITS == "x86_64" ]; then
					#YUM_REPO=rpmforge-release-0.5.3-1.el5.rf.x86_64.rpm
					YUM_REPO=epel-release-5-4.noarch.rpm
					#REPO_URL_C=$REPO_URL$YUM_REPO
					REPO_URL_C=$REPO_URL/x86_64/$YUM_REPO
				elif [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
					#YUM_REPO=rpmforge-release-0.5.3-1.el5.rf.i386.rpm
					YUM_REPO=epel-release-5-4.noarch.rpm
					REPO_URL_C=$REPO_URL/i386/$YUM_REPO
			
				fi
				cd $SRCDIR
				wget $REPO_URL_C
				error_handler "Error during downloading of the EPEL YUM repo: script will exit now."
				rpm -Uvh $YUM_REPO
				sed -i 's/perl\*//' /etc/yum.conf
				#yum --enablerepo=rpmforge,rpmforge-extras install memcached
				yum -y install memcached
			elif [ ${OS_VER:0:1} \> "5" ]; then
				sed -i 's/perl\*//' /etc/yum.conf
				yum -y install memcached
			fi

			error_handler "Error during yum installation: script will exit now."
			
			service_management "chkconfig" "on" "memcached"
			service_management "service" "restart" "memcached"

		else
			SPECIFICS="\nMemcached server was already installed."
			echo -e "The memcached server was already installed. Continuing to the PHP module.";		
		fi
	fi
	
	read -p "Do you want to install the PHP memcache (1), memcached (2) module or none (3)? (press 1,2 or 3) " RESP
	if [ "$RESP" = "1" ]; then
		PECL_NAME=Memcache
		PECL_FILENAME=$MEMCACHEPECL
		PECL_SO=memcache.so
		LOG_ACTION="PHP Memcache"
	elif [ "$RESP" = "2" ]; then
		PECL_NAME=Memcached
		PECL_FILENAME=$MEMCACHEDPECL
		PECL_SO=memcached.so
		LOG_ACTION="PHP Memcached"
		
		cd $SRCDIR
		
		yum -y install cyrus-sasl-devel
		
		error_handler "Error during yum installation: script will exit now."
		
		if [ ${OS_VER:0:1} == "5" ]; then
			if [ -f /usr/local/lib/libmemcached.so ]; then
			
				echo -e "\nLibmemcached is already installed."
				
			else
				wget --no-check-certificate https://launchpad.net/libmemcached/1.0/0.53/+download/libmemcached-0.53.tar.gz
				
				error_handler "Error during downloading of libmemcached: script will exit now."
				
				tar -zxf libmemcached-0.53.tar.gz
				cd libmemcached-0.53
				./configure
				make clean && make && make install
				error_handler "Error during compilation of libmemcached."
			fi
		elif [ ${OS_VER:0:1} \> "5" ]; then		
			if [ -f /usr/local/lib/libmemcached.so ]; then
			
				echo -e "\nLibmemcached is already installed."
			
			else
				yum -y install libevent-devel
				
				error_handler "Error during yum installation: script will exit now."
				
				wget --no-check-certificate $LIBMEMCACHEDURL$LIBMEMCACHED.tar.gz
				
				error_handler "Error during downloading of libmemcached: script will exit now."
				
				tar -zxf $LIBMEMCACHED.tar.gz
				cd $LIBMEMCACHED
				./configure
				make clean && make && make install
				error_handler "Error during compilation of libmemcached."
			fi
		fi

	else
		PECL_NAME=none
	fi
	
	if [ $PECL_NAME == "none" ]; then
		echo -e "No PHP module selected.\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module

		##execute php_generic
		php_generic;
	fi
	pause
}

i_ssh2(){
	PECL_NAME=PHP-SSH2
	PECL_EXT=.tgz
	PECL_FILENAME=$SSH2PECL
	PECL_SO=ssh2.so
	EXTENSIONTYPE=regular
	CONFIGUREFLAG="--with-ssh2"

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module
		if ! rpm -qa | grep libssh2 || ! rpm -qa | grep libssh2-devel; then
			if [ ${OS_VER:0:1} == "5" ]; then
				CBITS=`uname -i`
				REPO_URL=http://mirrors.kernel.org/fedora-epel/5/

				if [ $CBITS == "x86_64" ]; then
					YUM_REPO=epel-release-5-4.noarch.rpm
					REPO_URL_C=$REPO_URL/x86_64/$YUM_REPO
				elif [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
					YUM_REPO=epel-release-5-4.noarch.rpm
					REPO_URL_C=$REPO_URL/i386/$YUM_REPO
			
				fi
				cd $SRCDIR
				wget $REPO_URL_C
				error_handler "Error during downloading of the EPEL YUM repo: script will exit now."
				rpm -Uvh $YUM_REPO
				yum -y install libssh2 libssh2-devel
			elif [ ${OS_VER:0:1} \> "5" ]; then
				yum -y install libssh2 libssh2-devel
			fi

			error_handler "Error during yum installation: script will exit now."

		else
			echo -e "The libssh2 was already installed. Continuing to the PHP module.";		
		fi
		##execute php_generic
		php_generic;
	fi
	pause
}

i_apc(){
	PECL_NAME=APC
	PECL_EXT=.tgz
	PECL_FILENAME=$APCPECL
	PECL_SO=apc.so
	EXTENSIONTYPE=regular

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module
		PHP_VER_MAJOR=${PHP_VER:0:3}
		PHP2_VER_MAJOR=${PHP_VER2:0:3}
		if [ "${PHP_VER_MAJOR//./}" == "54" ]; then
			PHP1_NOTICE=1
		elif [ "${PHP_VER_MAJOR//./}" -gt "54" ]; then
			PHP1_NOTICE=2
			COMMENTRA="PHP 1: APC is not compatible with PHP versions higher than 5.4.\n\n"
		fi

		if [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP != "no" ]; then
			if [ "${PHP2_VER_MAJOR//./}" == "54" ]; then
				PHP2_NOTICE=1
			elif [ "${PHP2_VER_MAJOR//./}" -gt "54" ]; then
				PHP2_NOTICE=2
				COMMENTRA="PHP 2: APC is not compatible with PHP versions higher than 5.4.\n\n"
			fi
		fi
		
		if [ "$PHP1_NOTICE" == "1" ]; then
			read -p "APC is not recommended for use with PHP 5.4. Do you wish to install this anyway? (y/n)" RESP
			if [ "$RESP" = "n" ] || [ "$RESP" = "N" ]; then
				PHP1_INSTALL=no
			fi
		fi
		if [ "$PHP2_NOTICE" == "1" ]; then
			read -p "APC is not recommended for use with PHP 5.4. Do you wish to install this anyway? (y/n)" RESP
			if [ "$RESP" = "n" ] || [ "$RESP" = "N" ]; then
				PHP2_INSTALL=no
			fi
		fi
		if [ "$PHP1_NOTICE" == "2" ]; then
			PHP1_INSTALL=no
		fi
		if [ "$PHP2_NOTICE" == "2" ]; then
			PHP2_INSTALL=no
		fi
		
		unset PHP1_NOTICE PHP2_NOTICE
		##execute php_generic
		php_generic;
		
	fi
	pause
}

i_phpredis(){
	PECL_NAME="PHP Redis"
	PECL_EXT=.tgz
	PECL_FILENAME=$REDISPECL
	PECL_SO=redis.so
	EXTENSIONTYPE=regular

	if grep -q "$PECL_SO" "/usr/local/lib/php.ini" && grep -q "$PECL_SO" "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	elif grep -q "$PECL_SO" "/usr/local/lib/php.ini" && ([ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ])); then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module

		##execute php_generic
		php_generic;
	fi
	pause
}

i_zendopcache(){
	PECL_NAME="Zend OPcache"
	PECL_EXT=.tgz
	PECL_FILENAME=$ZENDOPCACHEPECL
	PECL_SO=opcache.so
	EXTENSIONTYPE=zend
	## If Custombuild 2 is in effect: The zend EXTENSIONTYPE is only to be used for opcache!
	
	if grep -q "$PECL_SO" "/usr/local/lib/php.ini"; then
		echo -e "1. $PECL_NAME seems to be installed already!\n";
	else
		##process additional requirements for the module

		##execute php_generic
		# opcache specific php.ini variables are set in the php_generic function
		php_generic;

	fi
	pause
}

php_generic(){
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ]; then
		CB2_1PHP=`cat $DA_CUSTOMBUILD/options.conf |grep php1_release |cut -d '=' -f2`
		CB2_2PHP=`cat $DA_CUSTOMBUILD/options.conf |grep php2_release |cut -d '=' -f2`

		if [ $CB2_2PHP != "no" ]; then
			CB2_2PHP_SHORT=${CB2_2PHP//./}
			PHPIZE_DIR=/usr/local/php$CB2_2PHP_SHORT/bin
			if [ "$PHP1_INSTALL" != "no" ] && [ "$PHP2_INSTALL" != "no" ]; then
				PASSES="php1 php2"
			elif [ "$PHP1_INSTALL" == "no" ] && [ "$PHP2_INSTALL" != "no" ]; then
				PASSES="php2"
			elif [ "$PHP1_INSTALL" != "no" ] && [ "$PHP2_INSTALL" == "no" ]; then
				PASSES="php1"
			else
				unset PHP1_INSTALL PHP2_INSTALL
				COMMENTR="PHP Module was not built"
				return 1
			fi
		else
			if [ "$PHP1_INSTALL" != "no" ]; then
				PASSES="php1"
			else
				unset PHP1_INSTALL PHP2_INSTALL
				COMMENTR="PHP Module was not built"
				return 1
			fi
		fi	
	else
		if [ "$PHP1_INSTALL" != "no" ]; then
			PASSES="php1"
		else
			unset PHP1_INSTALL PHP2_INSTALL
			COMMENTR="PHP Module was not built"
			return 1
		fi
	fi
	
	unset PHP1_INSTALL PHP2_INSTALL
	
	initcopy
	last_action
	
	cd $SRCDIR
	wget $PECLURL$PECL_FILENAME$PECL_EXT

	error_handler "Error during downloading of PECL package: script will exit now."

	tar zxvf $PECL_FILENAME$PECL_EXT
	
	error_handler "Error during extraction of PECL package: script will exit now."
	
	for PHP_PASS in $PASSES
	do
		## Check if a 10-directadmin.ini exists, and if it does, skip this part if a zend module is to be built.
		if ([ $PHP_PASS == "php1" ] && [ "$EXTENSIONTYPE" == "zend" ] && [ -f /usr/local/lib/php.conf.d/10-directadmin.ini ]) || ([ $PHP_PASS == "php2" ] && [ "$EXTENSIONTYPE" == "zend" ] && [ -f /usr/local/php$CB2_2PHP_SHORT/lib/php.conf.d/10-directadmin.ini ]); then 
			if [ "$EXTENSIONTYPE" == "zend" ] && [ $PHP_PASS == "php1" ]; then
				## only build it once because custombuild 2 will add zend extensions to both PHP's
				$DA_CUSTOMBUILD/build set opcache yes
				$DA_CUSTOMBUILD/build opcache
			fi
		else
			cd $SRCDIR
			cd $PECL_FILENAME
			
			if [ $PHP_PASS == "php1" ]; then
				phpize
				./configure $CONFIGUREFLAG
			else
				$PHPIZE_DIR/phpize
				./configure --prefix=/usr/local/php$CB2_2PHP_SHORT --with-php-config=/usr/local/php$CB2_2PHP_SHORT/bin/php-config $CONFIGUREFLAG
			fi

			error_handler "Error during configure: script will exit now."
			
			make clean && make && make install >temp.txt

			if ! [ "$?" = "0" ]; then
				echo "failed during compilation: script will exit now."
				rm temp.txt
				exit 1
			fi
			
			ldconfig

			cat temp.txt
			echo -e "\n\n2. $PECL_NAME is compiled. This script will now attempt to add the extension_dir and $PECL_SO file to the php.ini.\n\n"

			if [ "$EXTENSIONTYPE" = "regular" ]; then
				sed -i 's./.\\/.g' $SRCDIR/$PECL_FILENAME/temp.txt
			fi

			PHP_EXT=`head -n 1 $SRCDIR/$PECL_FILENAME/temp.txt >$SRCDIR/$PECL_FILENAME/temp2.txt && cut -d':' -f2 $SRCDIR/$PECL_FILENAME/temp2.txt |tr -d ' '`

			rm temp.txt temp2.txt
			
			if [ $PHP_PASS == "php1" ]; then
				if [ -f /usr/local/lib/php.conf.d/10-directadmin.ini ] && [ "$EXTENSIONTYPE" = "zend" ]; then
					system_phpini="/usr/local/lib/php.conf.d/10-directadmin.ini $PHP5CGI"
				else
					system_phpini="/usr/local/lib/php.ini $PHP5CGI"
				fi
			else
				if [ -f /usr/local/php$CB2_2PHP_SHORT/lib/php.conf.d/10-directadmin.ini ] && [ "$EXTENSIONTYPE" == "zend" ]; then
					system_phpini="/usr/local/php$CB2_2PHP_SHORT/lib/php.conf.d/10-directadmin.ini"
				else
					system_phpini="/usr/local/php$CB2_2PHP_SHORT/lib/php.ini"
				fi
			fi
			
			if [ "$EXTENSIONTYPE" == "regular" ]; then
				for phpini in $system_phpini
				do
					sed -i '/extension='"$PECL_SO"'/d' $phpini
					sed -i "s/.*extension_dir =.*/extension_dir = \"$PHP_EXT\"/" $phpini
					echo "extension=$PECL_SO" >> $phpini
				done
			else			
				for phpini in $system_phpini
				do
					echo "zend_extension=$PHP_EXT$PECL_SO" >> $phpini
					if [ "$PECL_SO" = "opcache.so" ]; then
						echo "opcache.memory_consumption=128" >> $phpini
						echo "opcache.interned_strings_buffer=8" >> $phpini
						echo "opcache.max_accelerated_files=4000" >> $phpini
						echo "opcache.revalidate_freq=60" >> $phpini
						echo "opcache.fast_shutdown=1" >> $phpini
						echo "opcache.enable_cli=1" >> $phpini
					fi
				done
			fi
		fi	
	done
	
	service_management "service" "restart" "httpd"

	if grep -q "$PECL_SO" /usr/local/lib/php.ini || grep -q "$PECL_SO" /usr/local/lib/php.conf.d/10-directadmin.ini; then
		COMMENTR="$PECL_NAME is successfully installed.\nBackup copies of the cli and cgi php.ini files can be found in $SRCDIR/$NOW_DATE_INIT . This folder also contains rollback.sh to execute the rollback of all config files. $SPECIFICS";
		echo -e "3. $COMMENTR";
	elif grep -q "$PECL_SO" /usr/local/php$CB2_2PHP_SHORT/lib/php.ini || grep -q "$PECL_SO" /usr/local/php$CB2_2PHP_SHORT/lib/php.conf.d/10-directadmin.ini; then
		COMMENTR="$PECL_NAME is successfully installed in PHP installation 2.\nBackup copies of the cli and cgi php.ini files can be found in $SRCDIR/$NOW_DATE_INIT . This folder also contains rollback.sh to execute the rollback of all config files. $SPECIFICS";
		echo -e "3. $COMMENTR";
	else
		echo -e "3. The extension cannot be found in the php.ini. Changes to the php.ini's are now rolled back. You can make the changes manually.\n\n"
		rollback
		exit 1
	fi
	
	unset PASSES CB2_1PHP CB2_2PHP PHPIZE_DIR CB2_2PHP_SHORT
}

i_xsl() {
	PHP_EXT=1
	EXT_NAME=with-xsl
	EXT_NAME2=XSL
	
	if php -m |grep -i -q $EXT_NAME2; then 
		echo -e "The $EXT_NAME2 extension was already installed.";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension
		if ! rpm -qa | grep -q libxslt-devel; then
			yum -y install libxslt libxslt-devel
			error_handler "Error during yum installation: script will exit now."
		fi
		## Add extension and build PHP
		php_build_extension_a
	fi
	pause
}

i_ldap() {
	PHP_EXT=1
	EXT_NAME=with-ldap
	EXT_NAMEb=with-ldap-sasl
	EXT_NAME2=LDAP
	
	if php -m |grep -i -q $EXT_NAME2; then 
		echo -e "The $EXT_NAME2 extension was already installed.";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension
		if ! rpm -qa | grep -q openldap-devel; then
			yum -y install openldap-devel
			error_handler "Error during yum installation: script will exit now."
		fi
		
		if ! [ -f /usr/lib/libldap.so ] && [ -f /usr/lib64/libldap.so ]; then
			for FILE in /usr/lib64/libldap*; do ln -s "$FILE" "/usr/lib/${FILE//\/usr\/lib64\//}"; done
		fi
		if ! [ -f /usr/lib/liblber.so ] && [ -f /usr/lib64/liblber.so ]; then
			for FILE in /usr/lib64/liblber*; do ln -s "$FILE" "/usr/lib/${FILE//\/usr\/lib64\//}"; done
		fi

		## Add extension and build PHP
		php_build_extension_a
	fi
	pause
}

i_tidy() {
	PHP_EXT=1
	EXT_NAME=with-tidy
	EXT_NAME2=Tidy
	
	if php -m |grep -i -q $EXT_NAME2; then 
		echo -e "The $EXT_NAME2 extension was already installed.";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension
		if ! rpm -qa | grep -q libtidy; then
			yum -y install libtidy libtidy-devel
			error_handler "Error during yum installation: script will exit now."
		fi
		## Add extension and build PHP
		php_build_extension_a
	fi
	pause
}

i_intl() {
	PHP_EXT=1
	EXT_NAME=enable-intl
	EXT_NAMEb=with-icu-dir=\\/usr\\/local\\/icu
	EXT_NAME2=Intl
	
	if php -m |grep -i -q $EXT_NAME2; then 
		echo -e "The $EXT_NAME2 extension was already installed.";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension

		cd $SRCDIR
		
		if [ ${OS_VER:0:1} == "5" ]; then
			## 4.8.1 is the last version compatible with centos 5
			wget http://download.icu-project.org/files/icu4c/4.8.1.1/icu4c-4_8_1_1-src.tgz
			error_handler "Error during downloading of ICU source: script will exit now."
			tar -zxf icu4c-4_8_1_1-src.tgz
			cd icu/source
			./configure --prefix=/usr/local/icu
			make clean && make && make install

			error_handler "Error during compilation of ICU."

		elif [ ${OS_VER:0:1} \> "5" ]; then
			LIBICU_VER=`yum info libicu-devel |grep -i version |head -1 |awk '{print $3}'`
			LIBICU_VER_MAJOR=${LIBICU_VER:0:1}
			if [ "$LIBICU_VER_MAJOR" \> "3" ]; then
				read -p "libicu is installed and is version 4 or higher ($LIBICU_VER). This script can install version 5 in an alternative directory (/usr/local/icu). Do you want this? (y/n) " RESP
				if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
					GOODTOGO=1
				else
					unset EXT_NAMEb
				fi
			fi
			
			if [ "$GOODTOGO" == "1" ]; then
				wget $ICUURL$ICU.tgz
				error_handler "Error during downloading of ICU source: script will exit now."
				tar -zxf $ICU.tgz
				cd icu/source
				./configure --prefix=/usr/local/icu
				make clean && make && make install
				
				error_handler "Error during compilation of ICU."
				
			fi
			
			unset LIBICU_VER LIBICU_VER_MAJOR
		fi
		
		## Add extension and build PHP
		php_build_extension_a
	fi
	pause
}

i_imap() {
	PHP_EXT=1
	EXT_NAME=with-imap=\\/usr\\/local\\/php-imap
	EXT_NAMEb=with-imap-ssl
	EXT_NAME2=IMAP
	
	if php -m |grep -i -q $EXT_NAME2; then 
		echo -e "The $EXT_NAME2 extension was already installed.";
	else
		##execute function to check for custom folder
		customfolder
		##backup all config files
		initcopy
		last_action
		##process additional requirements for the extension
		##This is a slightly modified version of the imap install code by Martynas Bendorius (smtalk): http://forum.directadmin.com/showthread.php?t=45434
		cd $SRCDIR
		B64=0
		B64COUNT=`uname -m | grep -c 64`
		if [ "$B64COUNT" -eq 1 ]; then
			B64=1
			LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib
			export LD_LIBRARY_PATH
		fi

		if [ ! -e /usr/include/krb5.h ] && [ -e /etc/redhat-release ]; then
			yum -y install krb5-devel
			error_handler "Error during yum installation: script will exit now."
		fi

		wget $PHPIMAPURL$PHPIMAP.tar.gz
		error_handler "Error during download of IMAP source."

		tar xzf $PHPIMAP.tar.gz
		cd $PHPIMAP

		perl -pi -e 's#SSLDIR=/usr/local/ssl#SSLDIR=/etc/pki/tls#' src/osdep/unix/Makefile
		perl -pi -e 's#SSLINCLUDE=\$\(SSLDIR\)/include#SSLINCLUDE=/usr/include/openssl#' src/osdep/unix/Makefile
		perl -pi -e 's#SSLLIB=\$\(SSLDIR\)/lib#SSLLIB=/usr/lib/openssl#' src/osdep/unix/Makefile
		if [ ${B64} -eq 0 ]; then
			make slx
		else
			make slx EXTRACFLAGS=-fPIC
		fi
		
		error_handler "Error during compilation step 'make slx'."

		mkdir -p /usr/local/php-imap/include
		mkdir -p /usr/local/php-imap/lib
		chmod -R 077 /usr/local/php-imap
		cp -f c-client/*.h /usr/local/php-imap/include/
		cp -f c-client/*.c /usr/local/php-imap/lib/
		cp -f c-client/c-client.a /usr/local/php-imap/lib/libc-client.a
		## Add extension and build PHP
		php_build_extension_a
	fi
	pause
}

php_update_minor() {
	PHP_EXT=0
	MINOR_REBUILD=yes
	php_build_extension_a
	pause	
}

php_upgrade() {
	PHP_EXT=0
	PHP_VER_MAJOR=${PHP_VER:0:3}
	PHP_CURRENT=$PHP_VER_MAJOR
	PHP_MAIN_INI=/usr/local/lib/php.ini
	ALT_INI_FILE=""
	
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ]; then
		CB2_1PHP=`cat $DA_CUSTOMBUILD/options.conf |grep php1_release |cut -d '=' -f2`
		if [ $CB2_2PHP != "no" ]; then
			CB2_2PHP=`cat $DA_CUSTOMBUILD/options.conf |grep php2_release |cut -d '=' -f2`
			CB2_2PHP_SHORT=${CB2_2PHP//./}
			PHP_VER2_MAJOR=${PHP_VER2:0:3}
			
			if [ $PHP_VER_MAJOR == $PHP_UPGRADE ] || [ $PHP_VER2_MAJOR == $PHP_UPGRADE ]; then
				COMMENTR="You can not have both PHP installations set to the same major PHP version."
				return 1
			fi
			clear
			
			read -p "Which PHP installation do you wish to upgrade to $PHP_UPGRADE?
	1 = PHP 1 (currently at $PHP_VER)
	2 = PHP 2 (currently at $PHP_VER2)
	3 = cancel and go back to menu
	(1/2/3):" RESP
			
			if [ "$RESP" != "1" ] && [ "$RESP" != "2" ]; then
				return 1
			elif [ "$RESP" == "1" ]; then
				PHP_RELEASE=php1_release
				PHP_MAIN_INI=/usr/local/lib/php.ini
				ALT_INI_FILE=/usr/local/lib/php.conf.d/10-directadmin.ini
			elif [ "$RESP" == "2" ]; then
				PHP_RELEASE=php2_release
				PHP_VER_MAJOR=$PHP_VER2_MAJOR
				PHP_CURRENT=$PHP_VER2_MAJOR
				PHP_MAIN_INI=/usr/local/php${PHP_UPGRADE//./}/lib/php.ini
				ALT_INI_FILE=/usr/local/php${PHP_UPGRADE//./}/lib/php.conf.d/10-directadmin.ini
			fi
		else
			PHP_RELEASE=php1_release
			PHP_MAIN_INI=/usr/local/lib/php.ini
			ALT_INI_FILE=/usr/local/lib/php.conf.d/10-directadmin.ini
		fi
	fi
	#exit 0

	## Check if upgrade is necessary
	if [ $PHP_VER_MAJOR == $PHP_UPGRADE ]; then
		echo -e "You are already running PHP version $PHP_UPGRADE!";
	elif [ $PHP_UPGRADE \< $PHP_VER_MAJOR ]; then
		echo -e "You are at PHP version $PHP_VER_MAJOR and want to go to $PHP_UPGRADE, which is not possible with this script.";
	else
		initcopy

		if [ "$PHP_RELEASE" == "php2_release" ]; then
			PHP_BIN=/usr/local/php${PHP_VER_MAJOR//./}/bin/php
		else
			PHP_BIN="php"
		fi
		
		if $PHP_BIN -m | grep -qi "ionCube"; then
			IONCUBE=1
		else
			IONCUBE=0
		fi

		if $PHP_BIN -m | grep -qi "Zend Guard Loader"; then
			GUARD=1
		else
			GUARD=0
		fi

		if $PHP_BIN -m | grep -qi "Zend Optimizer"; then
			OPTIMIZER=1
		else
			OPTIMIZER=0
		fi

		## check if zend opcache is enabled prior to upgrading PHP
		if $PHP_BIN -m |grep -iq opcache && [ "$PHP_RELEASE" != "php2_release" ]; then
			PHP_OPCACHE_CHECK=1
		else
			PHP_OPCACHE_CHECK=0
		fi
		
		## Saving binary files and user dir just to be sure
		#cp -p /usr/local/bin/php $SRCDIR/$NOW_DATE_INIT/php.binary
		#cp -p /usr/local/php5/bin/php-cgi $SRCDIR/$NOW_DATE_INIT/php-cgi.binary
		#cd /usr/local/directadmin/data ; tar zcvf $SRCDIR/$NOW_DATE_INIT/users.tgz users 

		## Increment php version
		if [ ${CUSTOMBUILD_VER:0:1} == 1 ] && [ "$PHP_UPGRADE" == "5.6" ]; then
				clear
				read -p "PHP 5.6 is not officially supported with custombuild 1.x. However, it is still possible using a small hack of the custombuild script. Do you wish to continue with the upgrade to PHP 5.6? (y/n) " RESP
				if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
					echo -e "\nProceeding upgrade to PHP 5.6.\n"
				else
					echo -e "\nCancelled upgrade to PHP 5.6.\n"
					exit 1
				fi
		elif [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
			if ! [ "$PHP_UPGRADE" == "5.6" ]; then
				$DA_CUSTOMBUILD/build set php5_ver $PHP_UPGRADE
			fi
		else
			$DA_CUSTOMBUILD/build set $PHP_RELEASE $PHP_UPGRADE
		fi
		
		last_action
		php_build_extension_a
	
		if [ "$PHP_RELEASE" == "php2_release" ]; then
			PHP_LOCATION=/usr/local/php${PHP_UPGRADE//./}
			PHP_EXT_VAL=`$PHP_LOCATION/bin/php -i |grep -i "php extension =>" |tr -cd [0-9]`
		else
			PHP_LOCATION=/usr/local
			PHP_EXT_VAL=`php -i |grep -i "php extension =>" |tr -cd [0-9]`
		fi
		
		## Ioncube stuffs. If 10-directadmin.ini exists, skip this step because custombuild overwites it
		if [ "$IONCUBE" == "1" ] && ! [ -f $ALT_INI_FILE ]; then
			if [ -d /usr/local/lib/ioncube ]; then
				cd /usr/local/lib
				rm ioncube_loaders_lin*tar.gz

				CBITS=`uname -i`
				if [ $CBITS == "x86_64" ]; then
					wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
					tar zxvf ioncube_loaders_lin_x86-64.tar.gz
				elif [ $CBITS == "i386" ] || [ $CBITS == "i686" ]; then
					wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz
					tar zxvf ioncube_loaders_lin_x86.tar.gz
				fi
				if ! [ "$?" = "0" ]; then
					COMMENTR="$COMMENTR \n\n Execution failed during ioncube loader download/install. Needs to be done manually."
				
				fi
			else
				$DA_CUSTOMBUILD/build set ioncube yes
				if [ -f $DA_CUSTOMBUILD/ioncube_loaders_lin_x86-64.tar.gz ]; then
					rm -f $DA_CUSTOMBUILD/ioncube_loaders_lin_x86-64.tar.gz
				fi
				sed -i '/ioncube_loader_lin/d' /usr/local/lib/php.ini
				if [ -n "$PHP5CGI" ]; then
					sed -i '/ioncube_loader_lin/d' /usr/local/etc/php5/cgi/php.ini
				fi
				$DA_CUSTOMBUILD/build ioncube
			fi
		fi
		
		user_phpini=`find /home/*/etc/ -type f -name php.ini`
		system_phpini="$PHP_MAIN_INI $PHP5CGI"
		all_phpini="${user_phpini} ${system_phpini}"

		## Build list of removed php.ini directives and stuff that needs to be commented out
		if [ $PHP_UPGRADE == 5.3 ]; then
			REMOVED_FUNCTIONS="zend_optimizer.version zend_extension_debug zend_extension_debug_ts zend_extension_ts zend_extension_manager.optimizer zend_extension_manager.optimizer_ts"
		elif [ $PHP_UPGRADE == 5.4 ] || [ $PHP_UPGRADE == 5.5 ] || [ $PHP_UPGRADE == 5.6 ]; then
			REMOVED_FUNCTIONS="zend_optimizer.version zend_extension_debug zend_extension_debug_ts zend_extension_ts zend_extension_manager.optimizer zend_extension_manager.optimizer_ts register_globals register_long_arrays open_basedir allow_call_time_pass_reference safe_mode magic_quotes magic_quotes_gpc magic_quotes_runtime magic_quotes_sybase define_syslog_variables highlight.bg y2k_compliance mbstring.script_encoding safe_mode_protected_env_vars safe_mode_allowed_env_vars safe_mode_gid safe_mode_include_dir safe_mode_exec_dir session.bug_compat_42 session.bug_compat_warn"
		fi

		## Make required changes/updates for the listed php versions.
		## PHP 5.3, capture both upgrade to 5.3 as well as upgrade to anything over 5.2 to fix changes that were made in 5.3
		
		## Zend opcache is included in php 5.5 and higher but needs to be enabled
		if [ $PHP_UPGRADE == 5.5 ] || [ $PHP_UPGRADE == 5.6 ]; then
			unset MOD[8]
			if [ "$PHP_OPCACHE_CHECK" == "0" ]; then
				read -p "PHP 5.5 and 5.6 have Zend OPcache built in but not enabled. Do you wish to enable this? (y/n) " RESP
				if [ "$RESP" == "y" ]; then
					if [ -f $PHP_LOCATION/lib/php/extensions/no-debug-non-zts-$PHP_EXT_VAL/opcache.so ]; then
						if [ -f $ALT_INI_FILE ]; then
							## The 10-directadmin.ini file is overwritten every time php is built, so use the options.conf setting
							if [ `grep -i '^zend=' $DA_CUSTOMBUILD/options.conf |cut -d'=' -f2` == "yes" ]; then
								## php builds will fail if both zend and opcache are set to yes
								$DA_CUSTOMBUILD/build set zend no
								GUARD=0
								OPTIMIZER=0
							fi
							$DA_CUSTOMBUILD/build set opcache yes
							$DA_CUSTOMBUILD/build opcache
						else
							for phpini in $system_phpini
							do
								echo "zend_extension=$PHP_LOCATION/lib/php/extensions/no-debug-non-zts-$PHP_EXT_VAL/opcache.so" >> $phpini
								echo "opcache.memory_consumption=128" >> $phpini
								echo "opcache.interned_strings_buffer=8" >> $phpini
								echo "opcache.max_accelerated_files=4000" >> $phpini
								echo "opcache.revalidate_freq=60" >> $phpini
								echo "opcache.fast_shutdown=1" >> $phpini
								echo "opcache.enable_cli=1" >> $phpini
							done
						fi
					fi
				fi
			else
				if [ -f $PHP_LOCATION/lib/php/extensions/no-debug-non-zts-$PHP_EXT_VAL/opcache.so ]; then
					for phpini in $system_phpini
					do
						sed -i "s/^zend_extension=\/usr\/local\/lib\/php\/extensions\/no-debug-non-zts-.*\/opcache.so/zend_extension=\/usr\/local\/lib\/php\/extensions\/no-debug-non-zts-$PHP_EXT_VAL\/opcache.so/" /usr/local/lib/php.ini
					done
				fi
			fi
			unset PHP_OPCACHE_CHECK
		fi

		if [ $PHP_UPGRADE == 5.3 ] && ! [ -f $ALT_INI_FILE ]; then
			if [ "$GUARD" == "1" ] || [ "$OPTIMIZER" == "1" ]; then
				$DA_CUSTOMBUILD/build set zend yes
				$DA_CUSTOMBUILD/build zend
			fi
			$DA_CUSTOMBUILD/build squirrelmail
		fi

		if [ $PHP_UPGRADE == 5.4 ] && ! [ -f $ALT_INI_FILE ] && ([ "$GUARD" == "1" ] || [ "$OPTIMIZER" == "1" ]); then
			$DA_CUSTOMBUILD/build set zend yes
			$DA_CUSTOMBUILD/build zend
		fi

		## Update ioncube version, and comment removed php.ini directives.
		COUNTER=1;
		for phpini in $all_phpini
		do
			if [ $PHP_CURRENT == 5.2 ]; then
				sed -i -e 's/;date.timezone =/date.timezone = "'"$PHP_TIMEZONE"'"/' $phpini
				sed -i '/ZendOptimizer_'"$PHP_VER_MAJOR"'.so/s/^/;/' $phpini
				sed -i '/ZendExtensionManager.so/s/^/;/' $phpini
				echo "mail.add_x_header = On" >> $phpini
			fi

			sed -i 's/ioncube_loader_lin_'"$PHP_VER_MAJOR"'.so/ioncube_loader_lin_'"$PHP_UPGRADE"'.so/' $phpini
			sed -i -e 's/date.timezone = "UTC"/date.timezone = "'"$PHP_TIMEZONE"'"/' $phpini

			if [ -n "$REMOVED_FUNCTIONS" ]; then
				for COMMENT_FUNC in $REMOVED_FUNCTIONS
				do
					sed -i '/^'"$COMMENT_FUNC"'/ s/^/;/' $phpini
				done
			fi

			if [ $PHP_UPGRADE == 5.5 ] || [ $PHP_UPGRADE == 5.6 ]; then
				## no Zend Guard loader available yet for php 5.5 or 5.6
				sed -i '/^zend_extension=\/usr\/local\/lib\/ZendGuardLoader.so/ s/^/;/' $phpini
			fi
			
			## Remove modules built for the previous php version, and store them for display later
			if [ $COUNTER == 1 ]; then
				REBUILD=""
				for element in ${MOD[@]}
				do
					sed -i '/'"$element"'/d' $phpini
					if [ "$REBUILD" == "" ]; then
						REBUILD="$element"
					else
						REBUILD="$REBUILD $element"
					fi
				done
			else
				for element in ${MOD[@]}
				do
					sed -i '/'"$element"'/d' $phpini
				done
			fi
		((COUNTER++))
		done

		unset MOD COUNTER

		if [ $BUILD_TYPE == "3" ]; then
			sed -i 's/#LoadModule suphp_module/LoadModule suphp_module/g' /etc/httpd/conf/httpd.conf
		fi
		service_management "service" "restart" "httpd"
	fi
        pause
	
}

php_build_extension_a() {
	BUILD_TYPE="";
	CUSTOM_PHP="";
	
	if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
		if grep -q "LoadModule ruid2_module" "/etc/httpd/conf/httpd.conf"; then
			echo -e "1. Mod_ruid2 is active, so only build the cli version. Php5_cgi & php5_cli updated in options.conf.\n";
			$DA_CUSTOMBUILD/build set php5_cli yes
			$DA_CUSTOMBUILD/build set php5_cgi no
			PHP_TWO_PASS=0
			BUILD_TYPE=1
		elif [ "$PHP_CLI_CGI" == "no" ]; then
			echo -e "1. Only build the cli version. Php5_cgi & php5_cli updated in options.conf.\n";
			$DA_CUSTOMBUILD/build set php5_cli yes
			$DA_CUSTOMBUILD/build set php5_cgi no
			PHP_TWO_PASS=0
			BUILD_TYPE=1
		elif grep -q "php5_cgi=yes" "$DA_CUSTOMBUILD/options.conf"; then
			echo -e "1. PHP cgi was active, so build the cgi version. Php5_cgi & php5_cli updated in options.conf.\n";
			$DA_CUSTOMBUILD/build set php5_cli no
			$DA_CUSTOMBUILD/build set php5_cgi yes
			PHP_TWO_PASS=0
			BUILD_TYPE=2
		else
			## requires two passes
			echo -e "1. Build the PHP cli and cgi version. Php5_cgi & php5_cli updated in options.conf.\n";
			$DA_CUSTOMBUILD/build set php5_cli no
			$DA_CUSTOMBUILD/build set php5_cgi yes
			PHP_TWO_PASS=1
			BUILD_TYPE=3
		fi
		
		echo -e "\n\n";
		if [ "$BUILD_TYPE" == "1" ]; then
			CUSTOM_PHP=ap2
			php_build_extension
		elif [ "$BUILD_TYPE" == "2" ]; then
			CUSTOM_PHP=suphp
			php_build_extension
		elif [ "$BUILD_TYPE" == "3" ]; then
			CUSTOM_PHP=suphp
			php_build_extension
			PASS=1
		fi
		if [ "$PASS" == "1" ]; then
			CUSTOM_PHP=ap2
			$DA_CUSTOMBUILD/build set php5_cli yes
			$DA_CUSTOMBUILD/build set php5_cgi no
			php_build_extension
		fi
	else
		PHP_TWO_PASS=0
		BUILD_TYPE=1
		CUSTOM_PHP=ap2
		php_build_extension
	fi
}

php_build_extension_b() {
	BUILD_TYPE="";
	CUSTOM_PHP="";

	PHP_TWO_PASS=0
	BUILD_TYPE=1
	php_build_extension
	
}

php_build_extension() {
	if [ "$PHP_EXT" == "1" ]; then
		
		##check and add extension to configure.php5
		
		if [ ${CUSTOMBUILD_VER:0:1} == 2 ]; then
			CONFIGURE_FILES="configure.php53 configure.php54 configure.php55 configure.php56"
			#all_phpini="${user_phpini} ${system_phpini}"
		else
			CONFIGURE_FILES="configure.php5"
		fi
		
		for configure_file in $CONFIGURE_FILES
		do
			if grep -q "\-\-$EXT_NAME" "$DA_CUSTOMBUILD/custom/$CUSTOM_PHP/$configure_file"; then
				echo -e "--$EXT_NAME does already exist!\n";
			else
				cd $DA_CUSTOMBUILD/custom/$CUSTOM_PHP/
				if [ -n "$EXT_NAMEb" ]; then
					sed '${s/$/ \\\n        --'"$EXT_NAME"' \\\n        --'"$EXT_NAMEb"'/}' $configure_file >$configure_file.new && mv $configure_file.new $configure_file
				else
					sed '${s/$/ \\\n        --'"$EXT_NAME"'/}' $configure_file >$configure_file.new && mv $configure_file.new $configure_file
				fi
				chmod 755 $DA_CUSTOMBUILD/custom/$CUSTOM_PHP/$configure_file
				if grep -q "\-\-$EXT_NAME" "$DA_CUSTOMBUILD/custom/$CUSTOM_PHP/$configure_file"; then
					echo -e "--$EXT_NAME line added to the $configure_file\n";
				else
					echo "--$EXT_NAME string not found in $configure_file, aborting.";
					rollback
					exit 1
				fi
			fi
		done
	fi

	if [ "$PHP_EXT" == "1" ]; then
		clear
		read -p "Do you wish to rebuild PHP now (y), or add some more extensions first (n)? (y/n): " RESP
		if [ "$RESP" = "n" ] || [ "$RESP" = "N" ]; then
			COMMENTR="The extension ($EXT_NAME2) is successfully added to the configuration files, but PHP will need to be rebuilt for this addition to take effect. You can rebuild php with option 200 or by selecting another extension to install and proceed with the PHP rebuild."
			return 1
		fi
	fi
	
	cd $DA_CUSTOMBUILD

	MEMTEMP=`sed -n -e '/^MemTotal/s/^[^0-9]*//p' /proc/meminfo  | cut -d 'k' -f1 |bc`
	MINTEMP=2000000;

	if [ $MEMTEMP -ge $MINTEMP ]; then
		GOODTOGO=1
	else
		read -p "You have less than 2GB of memory available, which may cause the PHP build to fail. Attempt a build anyway? (y/n) " RESP
		if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
			GOODTOGO=1
		fi
	fi
	
	if [ "$GOODTOGO" == "1" ]; then
		if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
			if [ "$PASS" == "0" ]; then
				if [ "$PHP_UPGRADE" == "5.4" ] || [ "$PHP_UPGRADE" == "5.5" ] || [ "$PHP_UPGRADE" == "5.6" ]; then
					$DA_CUSTOMBUILD/build set custombuild 1.2
					./build update
				fi
				./build options
				
				error_handler "Error during build options! Check the options.conf for errors." "rollback"

				./build update
				
				error_handler "Error during build update! Check the options.conf for errors." "rollback"
				
				if [ "$PHP_UPGRADE" == "5.6" ]; then
					## custombuild 1.2 does not allow for upgrading to PHP 5.6, so we need a dirty hack of the custombuild script.
					cp -p build build.ori
					## also copy the build script to the rollback directory
					cp -p $DA_CUSTOMBUILD/build $SRCDIR/$NOW_DATE_INIT/configs/build
					echo "cp -p build $DA_CUSTOMBUILD/build" >> $SRCDIR/$NOW_DATE_INIT/rollback.sh
					
					sed -i "s/\&\& \[ \"\${PHP5_VER_OPT}\" != \"5.5\" \]/\&\& \[ \"\${PHP5_VER_OPT}\" != \"5.5\" \] \&\& \[ \"\${PHP5_VER_OPT}\" != \"5.6\" \]/" build

					sed -i "s/|| \[ \"\${PHP5_VER_OPT}\" = \"5.5\" \]/|| \[ \"\${PHP5_VER_OPT}\" = \"5.5\" \] || \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]/" build

					sed -i "s/PHP5IONCUBE=ioncube_loader_\${OS_EXT}_5.5.so/PHP5IONCUBE=ioncube_loader_\${OS_EXT}_5.5.so\\nelif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\nPHP5IONCUBE=ioncube_loader_\${OS_EXT}_5.6.so/" build

					sed -i "s/PHP_INI_SOURCE=php.ini-dist/PHP_INI_SOURCE=php.ini-dist\\nif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\nPHP5_VER=\`getVer php56\`\\nPHP_INI_SOURCE=php.ini-production\\nfi\\n/" build

					sed -n "/if \[ \"\${PHP5_CLI_OPT}\" = \"yes\" ] || \[ \"\${PHP5_CGI_OPT}\" = \"yes\" \] ; then/,/else/p" build >temp.txt
					sed "s/else/elif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\ngetFile php-\${PHP5_VER}.tar.gz php56\\nelse/" temp.txt >temp2.txt
					cat temp2.txt | tail -n +2 | head -n -1 > temp2.txt.new && mv temp2.txt.new temp2.txt
					sed -i -ne "/if \[ \"\${PHP5_CLI_OPT}\" = \"yes\" ] || \[ \"\${PHP5_CGI_OPT}\" = \"yes\" \] ; then/ {p; r temp2.txt" -e ":a; n; /else/ {p; b}; ba}; p" build
					rm temp.txt temp2.txt

					sed -n "/if \[ \"\${PHP5_CGI_OPT}\" = \"yes\" ] || \[ \"\${PHP5_CLI_OPT}\" = \"yes\" \]; then/,/else/p" build >temp.txt
					sed "s/else/elif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\ngetFile php-\${PHP5_VER}.tar.gz php56\\nelse/" temp.txt >temp2.txt
					cat temp2.txt | tail -n +2 | head -n -1 > temp2.txt.new && mv temp2.txt.new temp2.txt
					sed -i -ne "/if \[ \"\${PHP5_CGI_OPT}\" = \"yes\" ] || \[ \"\${PHP5_CLI_OPT}\" = \"yes\" \]; then/ {p; r temp2.txt" -e ":a; n; /else/ {p; b}; ba}; p" build
					rm temp.txt temp2.txt


					sed -n "/doPhp5_suphp() {/,/else/p" build >temp.txt
					sed "s/else/elif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\ngetFile php-\${PHP5_VER}.tar.gz php56\\nelse/" temp.txt >temp2.txt
					cat temp2.txt | tail -n +2 | head -n -1 > temp2.txt.new && mv temp2.txt.new temp2.txt
					sed -i -ne "/doPhp5_suphp() {/ {p; r temp2.txt" -e ":a; n; /else/ {p; b}; ba}; p" build
					rm temp.txt temp2.txt


					sed -n "/doPhp5() {/,/else/p" build >temp.txt
					sed "s/else/elif \[ \"\${PHP5_VER_OPT}\" = \"5.6\" \]; then\\ngetFile php-\${PHP5_VER}.tar.gz php56\\nelse/" temp.txt >temp2.txt
					cat temp2.txt | tail -n +2 | head -n -1 > temp2.txt.new && mv temp2.txt.new temp2.txt
					sed -i -ne "/doPhp5() {/ {p; r temp2.txt" -e ":a; n; /else/ {p; b}; ba}; p" build
					rm temp.txt temp2.txt
										
					$DA_CUSTOMBUILD/build set php5_ver $PHP_UPGRADE
					
					## A build update overwrites the build script, so first make sure that does not happen.
					sed -i "s/.\/build update_data;/cp -p build.php56 build\\n.\/build update_data;/" build
					cp -p build build.php56
					./build update
					cp -p build.php56 build
				fi
				
			fi
		fi
		./build php n
		
	else
		COMMENTR="There is not enough memory available to build PHP, aborting.";
		if [ "$MINOR_REBUILD" != "yes" ]; then
			rollback
		fi
		return 1
	fi
	
	if [ "$PHP_EXT" == "1" ]; then
		if php -m | grep -q -i $EXT_NAME2; then
			COMMENTR="$EXT_NAME2 is successfully installed.\nBackup copies of config files can be found in $SRCDIR/$NOW_DATE_INIT .$SPECIFICS";
			echo -e "$COMMENTR";
		else
			echo -e "The $EXT_NAME2 extension seems to be not loaded.\nBackup copies of config files can be found in $SRCDIR/$NOW_DATE_INIT .\n\n"
			rollback
			exit 1
		fi
	elif  [ "$PHP_EXT" == "0" ]; then
		if [ "$MINOR_REBUILD" == "yes" ]; then
			COMMENTR="PHP Rebuild is complete.";
			echo -e "$COMMENTR";
			unset MINOR_REBUILD
		else
			if [ "$PHP_RELEASE" == "php2_release" ]; then
				PHP_VER=`/usr/local/php${PHP_UPGRADE//./}/bin/php -v |head -n 1 |cut -d' ' -f2`
			else
				PHP_VER=`php -v |head -n 1 |cut -d' ' -f2`
			fi
			COMMENTR="PHP build to version $PHP_VER is complete.\nBackup copies of config files can be found in $SRCDIR/$NOW_DATE_INIT .";
			echo -e "$COMMENTR";
		fi
	fi
}

mod_ruid() {
	initcopy
	last_action
	if grep -q "^LoadModule ruid2_module" "/etc/httpd/conf/httpd.conf"; then
		echo -e "Mod_ruid2 seems to be installed already!\n";
	elif `httpd -M |grep -i 'ruid2'`; then
		echo -e "Mod_ruid2 seems to be installed already!\n";
	else
		if [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
			## custombuild 1
			##execute function to check for custom folder/files
			customfolder
		
			if ! [ -a /etc/httpd/conf/extra/httpd-directories.conf ]; then 
				echo "/etc/httpd/conf/extra/httpd-directories.conf does not exist. This file is required for mod_ruid2 to work.";
				exit 1;
			fi

			yum -y install libcap-devel
			error_handler "Error during yum installation: script will exit now."
			echo -e "\n\n";
			
			cd $SRCDIR
			wget $MOD_RUID_URL$MR2FILE

			error_handler "Error during downloading of mod_ruid2 source: script will exit now."
			
			if [ -f $MR2FILE ]
			then
				echo "$MR2FILE found.";
				tar xvjf $MR2FILE
				cd mod_ruid2-0.9.? && apxs -a -i -l cap -c mod_ruid2.c
				grep mod_ruid2 /etc/httpd/conf/httpd.conf
			else
				echo -e "$MR2FILE not found, aborting.\n"
				rollback
				exit 1
			fi

			rm -Rf $SRCDIR/mod_ruid2-0.9.?*

			if [ ! -d "$DA_CUSTOMBUILD/custom/ap2/conf/extra" ]; then
				mkdir -p $DA_CUSTOMBUILD/custom/ap2/conf/extra			
			fi
			
			if grep -q "LoadModule ruid2_module" "/etc/httpd/conf/httpd.conf"; then
				echo -e "mod_ruid2 downloaded, built and added to /etc/httpd/conf/httpd.conf\n";
				sed -i 's|\(Group apache\)|\1\n\n# Mod_ruid\nRMode config\nRUidGid apache access|g' /etc/httpd/conf/httpd.conf
				cp -p /etc/httpd/conf/httpd.conf $DA_CUSTOMBUILD/custom/ap2/conf/httpd.conf
				echo -e "Mod_ruid user/group added to httpd.conf, and httpd.conf copied to the custom folder.\n";
			else
				echo "mod_ruid2 string not found in /etc/httpd/conf/httpd.conf, aborting.";
				rollback
				exit 1
			fi

			if grep -q "RUidGid webapps webapps" "/etc/httpd/conf/extra/httpd-directories.conf"; then
				echo -e "RUidGid line already exists!\n";

			else
				cd $DA_CUSTOMBUILD
				sed -n '/<Directory \"\/var\/www\/html\"/,/<\/Directory/p' /etc/httpd/conf/extra/httpd-directories.conf >temp.txt
				sed 's/<\/Directory>/     RUidGid webapps webapps\n<\/Directory>/' temp.txt >temp2.txt
				cat temp2.txt | tail -n +2 | head -n -1 > temp2.txt.new && mv temp2.txt.new temp2.txt
				sed -i -ne '/<Directory \"\/var\/www\/html\">/ {p; r temp2.txt' -e ':a; n; /<\/Directory>/ {p; b}; ba}; p' /etc/httpd/conf/extra/httpd-directories.conf
				rm temp.txt temp2.txt
				if grep -q "RUidGid webapps webapps" "/etc/httpd/conf/extra/httpd-directories.conf"; then
					cp -p /etc/httpd/conf/extra/httpd-directories.conf $DA_CUSTOMBUILD/custom/ap2/conf/extra/httpd-directories-old.conf
					echo -e "RUidGid line added to the httpd-directories.conf, and copied to the custom folder.\n";
				else
					echo "RUidGid webapps webapps string not found in httpd-directories.conf, aborting.";
					rollback
					exit 1
				fi
			fi

			if grep -q "\-\-disable-posix" "$DA_CUSTOMBUILD/custom/ap2/configure.php5"; then
				echo -e "--disable-posix does already exist!\n";

			else
				cd $DA_CUSTOMBUILD/custom/ap2/
				sed '${s/$/ \\\n        --disable-posix/}' configure.php5 >configure.php5.new && mv configure.php5.new configure.php5
				chmod 755 $DA_CUSTOMBUILD/custom/ap2/configure.php5
				if grep -q "\-\-disable-posix" "$DA_CUSTOMBUILD/custom/ap2/configure.php5"; then
					echo -e "--disable-posix line added to the configure.php5\n";
				else
					echo "--disable-posix string not found in configure.php5, aborting.";
					rollback
					exit 1
				fi
			fi

			cd $DA_CUSTOMBUILD

			$DA_CUSTOMBUILD/build set php5_cli yes
			$DA_CUSTOMBUILD/build set php5_cgi no

			echo -e "php5_cgi & php5_cli updated in options.conf\n\n";

			MEMTEMP=`sed -n -e '/^MemTotal/s/^[^0-9]*//p' /proc/meminfo  | cut -d 'k' -f1 |bc`
			MINTEMP=2000000;

			if [ $MEMTEMP -ge $MINTEMP ]; then
				GOODTOGO=1
			else
				read -p "You have less than 2GB of memory available, which may cause the PHP build to fail. Attempt a build anyway? (y/n) " RESP
				if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
					GOODTOGO=1
				fi
			fi
			
			if [ "$GOODTOGO" == "1" ]; then
				./build options
				
				error_handler "Error during build update! Check the options.conf for errors." "rollback"

				./build update
				./build php n
			else
				COMMENTR="There is not enough memory available to build PHP, aborting.";
				rollback
				return 1
			fi

			read -p "Convert the existing environment? (y/n) " RESP
			if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
				cd /usr/local/directadmin/scripts && ./set_permissions.sh user_homes
				find /home/*/domains/*/*_html -type d -print0 | xargs -0 chmod 755
				find /home/*/domains/*/*_html -type f -print0 | xargs -0 chmod 644
				find /home/*/domains/*/*_html -type f -name '*.cgi*' -exec chmod 755 {} \;
				find /home/*/domains/*/*_html -type f -name '*.pl*' -exec chmod 755 {} \;
				find /home/*/domains/*/*_html -type f -name '*.pm*' -exec chmod 755 {} \;
				cd /usr/local/directadmin/data/users && for i in `ls`; do { chown -R $i:$i /home/$i/domains/*/*_html;}; done; 
				echo -e "Existing environment converted.\n\n";
			else
				echo -e "Existing environment not converted.\n\n"
			fi

			read -p "Update squirrelmail permissions? (y/n) " RESP
			if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
				chown -R webapps:webapps /var/www/html/squirrelmail/data 
				echo -e "Squirrelmail permissions updated..\n\n"
			else
				echo -e "Squirrelmail permissions not updated..\n\n"
			fi

			RUID_SUCCESS=1
		else
			## custombuild 2
			customfolder
			cd $DA_CUSTOMBUILD
			
			RUID_PHP1=`grep -i '^php1_mode=' $DA_CUSTOMBUILD/options.conf | cut -d'=' -f2`
			RUID_PHP2=`grep -i '^php2_mode=' $DA_CUSTOMBUILD/options.conf | cut -d'=' -f2`

			if [ "$RUID_PHP1" != "mod_php" ] || ([ "$RUID_PHP2" != "mod_php" ] && [ "$CB2_2PHP" != "no" ]); then
				COMMENTR="Mod_ruid2 cannot be used if a PHP installation is not using mod_php."
				return 1
			fi
			
			$DA_CUSTOMBUILD/build set mod_ruid2 yes
			./build options
			./build update
			
			error_handler "Error during build update! Check the options.conf for errors."
			
			./build mod_ruid2
			
			read -p "Ownership of files to the owner of the account? (y/n) " RESP
			if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
				cd /usr/local/directadmin/scripts && ./set_permissions.sh user_homes
				find /home/*/domains/*/*_html -type d -print0 | xargs -0 chmod 755
				find /home/*/domains/*/*_html -type f -print0 | xargs -0 chmod 644
				find /home/*/domains/*/*_html -type f -name '*.cgi*' -exec chmod 755 {} \;
				find /home/*/domains/*/*_html -type f -name '*.pl*' -exec chmod 755 {} \;
				find /home/*/domains/*/*_html -type f -name '*.pm*' -exec chmod 755 {} \;
				cd /usr/local/directadmin/data/users && for i in `ls`; do { chown -R $i:$i /home/$i/domains/*/*_html;}; done; 
				echo -e "Existing environment converted.\n\n";
			else
				echo -e "Existing environment not converted.\n\n"
			fi
			
			## Disabled this block as it may not be needed anymore with cb2
			#read -p "Update squirrelmail permissions? (y/n) " RESP
			#if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
			#	chown -R webapps:webapps /var/www/html/squirrelmail/data 
			#	echo -e "Squirrelmail permissions updated..\n\n"
			#else
			#	echo -e "Squirrelmail permissions not updated..\n\n"
			#fi
			
			service_management "service" "restart" "httpd"
			
			RUID_SUCCESS=1
		fi
		
		if [ "$RUID_SUCCESS" == "1" ]; then
			cd $SRCDIR
			touch ruidtest.php
			echo "<?php" >> ruidtest.php
			echo "mkdir('ruidtest');" >> ruidtest.php
			echo "file_put_contents('ruidtest/test.txt', 'Hello!');" >> ruidtest.php
			echo "?>" >> ruidtest.php
			
			COMMENTR="Mod_ruid2 install completed. Test the installation by creating a php file within a document root, and executing it via a browser:\n\n<?php\nmkdir('ruidtest');\nfile_put_contents('ruidtest/test.txt', 'Hello!');\n?>\n\nFor your convenience, a file containing this code can be found at "$SRCDIR/"ruidtest.php \n\nBackups of the original config files are located in '$SRCDIR/$NOW_DATE_INIT'.\n\n";
			echo -e $COMMENTR
			
			unset RUID_SUCCESS
		fi
		
		unset RUID_PHP1 RUID_PHP2
	fi
	pause
}

mysql_minor() {
	MYSQL_VER=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`
	if [ ${MYSQL_VER:0:2} == "10" ]; then
		MYSQL_VER_MAJOR=${MYSQL_VER:0:4}
	else
		MYSQL_VER_MAJOR=${MYSQL_VER:0:3}
	fi
	MYSQL_TYPE=`cat /usr/local/directadmin/custombuild/options.conf |grep mysql_inst= |cut -d '=' -f2`

	cd $DA_CUSTOMBUILD
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ] && ([ $MYSQL_TYPE == "yes" ] || [ $MYSQL_TYPE == "no" ]); then
		# Custombuild was changed somewhere in 04/2015 where value 'yes' is no longer valid. Build update to get the newest custombuild.
		./build update
		MYSQL_TYPE=`cat /usr/local/directadmin/custombuild/options.conf |grep mysql_inst= |cut -d '=' -f2`
		if [ $MYSQL_TYPE == "no" ] && [ "$MARIADB" == "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mariadb
			$DA_CUSTOMBUILD/build set mariadb $MYSQL_VER_MAJOR
		elif [ $MYSQL_TYPE == "no" ] && [ "$MARIADB" != "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mysql
			$DA_CUSTOMBUILD/build set mysql $MYSQL_VER_MAJOR
		fi
	elif [ ${CUSTOMBUILD_VER:0:1} == 2 ] && ([ $MYSQL_TYPE != "yes" ] || [ $MYSQL_TYPE != "no" ]); then
		if [ "$MARIADB" == "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mariadb
			$DA_CUSTOMBUILD/build set mariadb $MYSQL_VER_MAJOR
		elif [ "$MARIADB" != "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mysql
			$DA_CUSTOMBUILD/build set mysql $MYSQL_VER_MAJOR
		fi
	else
		$DA_CUSTOMBUILD/build set mysql_inst yes
		$DA_CUSTOMBUILD/build set mysql $MYSQL_VER_MAJOR
	fi
	$DA_CUSTOMBUILD/build set mysql_backup yes
		
	./build options
	./build update

	error_handler "Error during build update! Check the options.conf for errors."
	
	ask_rpm_remove
	./build mysql
	
	MYSQL_VER_NEW=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`

	if [ "$MYSQL_VER" != "$MYSQL_VER_NEW" ] && [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
		echo -e "The MYSQL version changed. PHP needs to be rebuilt."
		MY_PHP="PHP needed to be rebuilt to use the newer Mysql client libraries."
		php_update_minor
	fi
	
	COMMENTR="Mysql has successfully been updated to $MYSQL_VER_NEW. $MY_PHP\n$COMMENTR"
	pause
}

mysql_upgrade() {
	MYSQL_VER=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`
	if [ ${MYSQL_VER:0:2} == "10" ]; then
		MYSQL_VER_MAJOR=${MYSQL_VER:0:4}
	else
		MYSQL_VER_MAJOR=${MYSQL_VER:0:3}
	fi
	
	if [ $MYSQL_UP \< $MYSQL_VER_MAJOR ]; then
		COMMENTR="You have version $MYSQL_VER_MAJOR, and want to go to $MYSQL_UP. This is a lower version, and not possible."
		echo $COMMENTR;
	else
		if [ "$MARIADB" == "1" ]; then
			## placeholder for future MariaDB updates
			mysql_upgrade_steps
		elif [[ ( "$MYSQL_VER_MAJOR" == "5.0" ) && ( "$MYSQL_UP" == "5.5" || "$MYSQL_UP" == "5.6" ) ]]; then
			## upgrade to 5.1 first
			STEP=1
			mysql_upgrade_steps
			STEP=2
			mysql_upgrade_steps
			if [ "$MYSQL_UP" == "5.6" ]; then
				STEP=3
				mysql_upgrade_steps
			fi
		elif [ "$MYSQL_VER_MAJOR" == "5.1" ] && [ "$MYSQL_UP" == "5.5" ]; then
			STEP=2
			mysql_upgrade_steps
		elif [ "$MYSQL_VER_MAJOR" == "5.1" ] && [ "$MYSQL_UP" == "5.6" ]; then
			## upgrade to 5.5 first
			STEP=2
			mysql_upgrade_steps
			STEP=3
			mysql_upgrade_steps
		elif [ "$MYSQL_VER_MAJOR" = "$MYSQL_UP" ]; then
			COMMENTR="You are already running MySQL $MYSQL_UP."
			echo -e $COMMENTR
		else
			## assume version is 5.5 or above
			STEP=3
			mysql_upgrade_steps		
		fi
	fi
	pause
}

mysql_upgrade_steps() {
	MYSQL_VER=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`
	if [ ${MYSQL_VER:0:2} == "10" ]; then
		MYSQL_VER_MAJOR=${MYSQL_VER:0:4}
	else
		MYSQL_VER_MAJOR=${MYSQL_VER:0:3}
	fi
	MYSQL_TYPE=`cat /usr/local/directadmin/custombuild/options.conf |grep mysql_inst= |cut -d '=' -f2`

	cd $DA_CUSTOMBUILD
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ] && ([ $MYSQL_TYPE == "yes" ] || [ $MYSQL_TYPE == "no" ]); then
		# Custombuild was changed somewhere in 04/2015 where value 'yes' is no longer valid. Build update to get the newest custombuild.
		./build update
		MYSQL_TYPE=`cat /usr/local/directadmin/custombuild/options.conf |grep mysql_inst= |cut -d '=' -f2`
		if [ $MYSQL_TYPE == "no" ] && [ "$MARIADB" == "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mariadb
		elif [ $MYSQL_TYPE == "no" ] && [ "$MARIADB" != "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mysql
		fi
	elif [ ${CUSTOMBUILD_VER:0:1} == 2 ] && ([ $MYSQL_TYPE != "yes" ] || [ $MYSQL_TYPE != "no" ]); then
		if [ "$MARIADB" == "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mariadb
		elif [ "$MARIADB" != "1" ]; then
			$DA_CUSTOMBUILD/build set mysql_inst mysql
		fi
	else
		$DA_CUSTOMBUILD/build set mysql_inst yes
	fi
	$DA_CUSTOMBUILD/build set mysql_backup yes
	
	if [ "$MARIADB" == "1" ]; then
		# specific for an upgrade from MariaDB 5.5 to 10.0 (https://mariadb.com/kb/en/mariadb/upgrading-from-mariadb-55-to-mariadb-100/)
		if [ -f /etc/my.cnf ]; then
			cd /etc
			MARIADB_REMOVED_FUNCTIONS="engine-condition-pushdown innodb-adaptive-flushing-method innodb-autoextend-increment innodb-blocking-buffer-pool-restore innodb-buffer-pool-pages innodb-buffer-pool-pages-blob innodb-buffer-pool-pages-index innodb-buffer-pool-restore-at-startup innodb-buffer-pool-shm-checksum innodb-buffer-pool-shm-key innodb-checkpoint-age-target innodb-dict-size-limit innodb-doublewrite-file innodb-ibuf-accel-rate innodb-ibuf-active-contract innodb-ibuf-max-size innodb-import-table-from-xtrabackup innodb-index-stats innodb-lazy-drop-table innodb-merge-sort-block-size innodb-persistent-stats-root-page innodb-read-ahead innodb-recovery-stats innodb-recovery-update-relay-log innodb-stats-update-need-lock innodb-sys-stats innodb-table-stats innodb-thread-concurrency-timer-based innodb-use-sys-stats-table xtradb-admin-command"
			MARIADB_CONFIGS="/etc/my.cnf /etc/my.cnf.d/server.cnf"
			cp -p my.cnf my.cnf.datoolbox
			tar -cf my.cnf.d.tar my.cnf.d
			for COMMENT_FUNC in $MARIADB_REMOVED_FUNCTIONS
			do
				for MARIADB_CNF in $MARIADB_CONFIGS
				do
					sed -i '/^'"$COMMENT_FUNC"'/ s/^/#/' $MARIADB_CNF
				done
			done
			
			for MARIADB_CNF in $MARIADB_CONFIGS
			do
				sed -i -e 's/innodb-fast-checksum/innodb-checksum-algorithm/' $MARIADB_CNF
				sed -i -e 's/innodb-flush-neighbor-pages/innodb-flush-neighbors/' $MARIADB_CNF
				sed -i -e 's/innodb-stats-auto-update/innodb-stats-auto-recalc/' $MARIADB_CNF
			done
			
			cd $DA_CUSTOMBUILD
		fi
		
		unset MYSQL_UP MARIADB_REMOVED_FUNCTIONS MARIADB_CONFIGS
		$DA_CUSTOMBUILD/build set mariadb $MARIADB_UP
		
		./build options
		./build update
		
		error_handler "Error during build update! Check the options.conf for errors."
		
		ask_rpm_remove
		./build mysql
		
		MYSQL_VER_NEW=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`
		
		COMMENTR="Mysql has successfully been upgraded to $MYSQL_VER_NEW."
		
	else
		if [ $STEP -eq 1 ]; then
			sed -i '/innodb_log_arch_dir/d' /etc/my.cnf
			$DA_CUSTOMBUILD/build set mysql 5.1
		elif [ $STEP -eq 2 ]; then
			yum -y install libaio
			error_handler "Error during yum installation: script will exit now."
			sed -i '/skip-locking/d' /etc/my.cnf
			sed -i -e 's/table_cache/table_open_cache/' /etc/my.cnf
			$DA_CUSTOMBUILD/build set mysql 5.5
		else
			$DA_CUSTOMBUILD/build set mysql $MYSQL_UP
		fi

		./build options
		./build update
		
		error_handler "Error during build update! Check the options.conf for errors."

		ask_rpm_remove
		./build mysql
		
		if [[ ( $STEP -eq 2 && "$MYSQL_UP" == "5.5" ) || ( $STEP -eq 3 && "$MYSQL_UP" == "5.6" ) ]]; then
			MYSQL_VER_NEW=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`

			if [ "$MYSQL_VER" != "$MYSQL_VER_NEW" ] && [ ${CUSTOMBUILD_VER:0:1} == 1 ]; then
				read -p "The MYSQL version changed. PHP needs to be rebuilt to use the newer client libraries. Do you want to rebuild it now? (y/n) " RESP
				if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ]; then
					MY_PHP="PHP needed to be rebuilt to use the newer Mysql client libraries."
					php_update_minor
				fi
			fi
		
			COMMENTR="Mysql has successfully been upgraded to $MYSQL_VER_NEW. $MY_PHP\n$COMMENTR"
		fi
	fi
}

show_menus() {
	## Empty previously used variables
	unset ALT_INI IMAGICK_I PDFLIB_I MAILPARSE_I MEMCACHE_I MEMCACHE_Id APC_I RUID_I XSL_I NOTNEEDED PHP_53 PHP_54 PHP_55 PHP_56 SPECIFICS REDIS_I GIT_I PHPREDIS_I MY_PHP ZENDOPCACHE_I EXTENSIONTYPE PY_I IONCUBE GUARD OPTIMIZER EXT_NAME EXT_NAMEb IMAP_I SSH_I LDAP_I TIDY_I INTL_I PSSRV_I PS_I MYSQL_UP MARIADB_UP PHP_EXT_VAL CONFIGUREFLAG GOODTOGO PHP_EXT PHP_VER_MAJOR PHP_CURRENT PHP_UPGRADE ALT_INI_FILE
	PECL_NAME=""
	PECL_EXT=""
	PECL_FILENAME=""
	PECL_SO=""
	PASS=0
	MYSQL_VER=`mysql --user=root -V |cut -d" " -f6 |tr -d , |sed s/\-MariaDB.*//I`
	PHP_VER=`php -v |head -n 1 |cut -d' ' -f2`
	PHP_VER_MAJOR=${PHP_VER:0:3}
	if [ ${CUSTOMBUILD_VER:0:1} == 2 ]; then
		CB2_2PHP=`cat $DA_CUSTOMBUILD/options.conf |grep php2_release |cut -d '=' -f2`
		if [ $CB2_2PHP != "no" ]; then
			CB2_2PHP_SHORT=${CB2_2PHP//./}
			PHP_VER2=`/usr/local/php$CB2_2PHP_SHORT/bin/php -v |head -n 1 |cut -d' ' -f2`
			PHP2_VER_MAJOR=${PHP_VER2:0:3}
			INI_LOOP="/usr/local/lib/php.ini /usr/local/php$CB2_2PHP_SHORT/lib/php.ini"
			PHP_LOOP="php /usr/local/php$CB2_2PHP_SHORT/bin/php"
			PHP2=yes
			PHPLINE="PHP1 Ver   : $PHP_VER | PHP2 Ver : $PHP_VER2\nMySQL Ver  : $MYSQL_VER"
			PHP_CURRENT="(PHP1: $PHP_VER PHP2: $PHP_VER2)"
		else
			PHPLINE="PHP Ver    : $PHP_VER | MySQL Ver : $MYSQL_VER"
			PHP_CURRENT="(Current Version: $PHP_VER)"
			INI_LOOP="/usr/local/lib/php.ini"
			PHP_LOOP="php"
		fi
	else
		PHPLINE="PHP Ver    : $PHP_VER | MySQL Ver : $MYSQL_VER"
		PHP_CURRENT="(Current Version: $PHP_VER)"
		INI_LOOP="/usr/local/lib/php.ini"
		PHP_LOOP="php"
	fi

	MHEADER3="PHP updates $PHP_CURRENT"

	## Check installed software/modules
	if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
		if [ "${PHP_VER:0:3}" == "5.4" ]; then
			NOTNEEDED="(Not stable with PHP 5.4)"
		fi
		if [ "${PHP_VER:0:3}" == "5.5" ]; then
			NOTNEEDED="(Not possible with PHP 5.5)"
		fi
	fi

	MOD_RESULT=$(get_module_status "imagick.so" "extension")
	IMAGICK_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[1]=`get_module_status_return $MOD_RESULT 2`
	
	MOD_RESULT=$(get_module_status "pdf.so" "extension")
	PDFLIB_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[2]=`get_module_status_return $MOD_RESULT 2`
	
	MOD_RESULT=$(get_module_status "mailparse.so" "extension")
	MAILPARSE_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[3]=`get_module_status_return $MOD_RESULT 2`
	
	MOD_RESULT=$(get_module_status "apc.so" "extension")
	APC_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[6]=`get_module_status_return $MOD_RESULT 2`
	
	MOD_RESULT=$(get_module_status "redis.so" "extension")
	PHPREDIS_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[7]=`get_module_status_return $MOD_RESULT 2`
	
	MOD_RESULT=$(get_module_status "ssh2.so" "extension")
	SSH_I=`get_module_status_return $MOD_RESULT 1 |tr '_' ' '`
	MOD[9]=`get_module_status_return $MOD_RESULT 2`
	
	for iniloop in $INI_LOOP
	do
		if grep -q "memcache.so" $iniloop; then
			if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
			MEMCACHE_I="(M yes)";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/lib/php.ini" ]; then
			MEMCACHE_I="PHP1: (M yes) "
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini" ]; then
			MEMCACHE_Ib="PHP2: (M yes) "
			fi
			MOD[4]="memcache.so";
			#break
		else
			if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
			MEMCACHE_I="(M no)";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/lib/php.ini" ]; then
			MEMCACHE_I="PHP1: (M no) "
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini" ]; then
			MEMCACHE_Ib="PHP2: (M no) "
			fi
		fi
	done	
		
	for iniloop in $INI_LOOP
	do
		if grep -q "memcached.so" $iniloop; then
			if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
			MEMCACHE_Id="(Md yes)";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/lib/php.ini" ]; then
			MEMCACHE_Id="(Md yes)\n                "
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini" ]; then
			MEMCACHE_Idb="(Md yes)"
			fi
			MOD[5]="memcached.so";
			#break
		else
			if [ ${CUSTOMBUILD_VER:0:1} == 1 ] || ([ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $CB2_2PHP == "no" ]); then
			MEMCACHE_Id="(Md no)";
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/lib/php.ini" ]; then
			MEMCACHE_Id="(Md no)\n                "
			elif  [ ${CUSTOMBUILD_VER:0:1} == 2 ] && [ $iniloop == "/usr/local/php$CB2_2PHP_SHORT/lib/php.ini" ]; then
			MEMCACHE_Idb="(Md no)"
			fi
		fi
	done
	
	XSL_I=$(get_extension_status "php" "xsl" "(installed)")
	LDAP_I=$(get_extension_status "php" "ldap" "(installed)")
	TIDY_I=$(get_extension_status "php" "tidy" "(installed)")
	INTL_I=$(get_extension_status "php" "intl" "(installed)")
	IMAP_I=$(get_extension_status "php" "imap" "(installed)")
	PS_I=$(get_extension_status "php" "pgsql" "(PHP: yes)")
	ZENDOPCACHE_I=$(get_extension_status "php" "opcache" "(installed)")
	PSSRV_I=$(get_extension_status "rpm" "postgres.*-server" "(Srv: yes)")
	REDIS_I=$(get_extension_status "file" "/etc/redis/redis.conf" "(installed)")
	if [ "$REDIS_I" != "(installed)" ]; then
		REDIS_I=$(get_extension_status "file" "/etc/redis.conf" "(installed)")
	fi
	GIT_I=$(get_extension_status "file" "/usr/local/bin/git" "(installed)")
	PY_I=$(get_extension_status "file" "/usr/local/bin/python2.7" "(installed)")
	RUID_I=$(get_extension_status "apache" "ruid2" "(installed)")
	
	if [ "$ZENDOPCACHE_I" == "(installed)" ]; then
		MOD[8]="opcache.so";
	fi

	PHP_CYCLE="5.3 5.4 5.5 5.6"
	
	for phploop in $PHP_CYCLE
	do
		phploop_short=${phploop//./}
		PHP_[$phploop_short]=""
		if php -v |head -n 1 |cut -d' ' -f2 |grep -q "^$phploop"; then
			if [ "$PHP2" == "yes" ]; then
				PHP_[$phploop_short]="(PHP1: inst)"
			else
				PHP_[$phploop_short]="(installed)"
			fi
		fi
		
		if [ "$PHP2" == "yes" ]; then
			if /usr/local/php$CB2_2PHP_SHORT/bin/php -v |head -n 1 |cut -d' ' -f2 |grep -q "^$phploop"; then
				PHP_[$phploop_short]="(PHP2: inst)"
			fi
		fi
	done
	unset PHP_CYCLE

	clear

	if ! [ "$REBUILD" == "" ]; then
		REBUILD="\n\nThese modules need to be rebuilt due to a major PHP version upgrade: $REBUILD "
	fi

	if [ -f $SRCDIR/lastaction.txt ] && [ -s $SRCDIR/lastaction.txt ]; then
		L_EPOCH=`cat $SRCDIR/lastaction.txt |cut -d':' -f1`
		L_EPOCH=`date -d @$L_EPOCH +'%d-%m-%y %H:%M'`
		L_ACTION=`cat $SRCDIR/lastaction.txt |cut -d':' -f2`
		L_DIR=`cat $SRCDIR/lastaction.txt |cut -d':' -f3`
		
		L_MENU="\nLast action:\n'$L_ACTION' at $L_EPOCH\nTo rollback, type 900"
	fi
	
	## Start menu structure
BLAH="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AUTHOR
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 $MHEADER
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$MITEM_1 $IMAGICK_I
$MITEM_2 $PDFLIB_I
$MITEM_3 $MAILPARSE_I
$MITEM_4 $MEMCACHE_I$MEMCACHE_Id$MEMCACHE_Ib$MEMCACHE_Idb
$MITEM_5 $APC_I$NOTNEEDED
$MITEM_6 $XSL_I
$MITEM_7 $PHPREDIS_I
$MITEM_8 $ZENDOPCACHE_I
$MITEM_9 $IMAP_I
$MITEM_10 $SSH_I
$MITEM_11 $LDAP_I
$MITEM_12 $TIDY_I
$MITEM_13 $INTL_I

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MHEADER2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MITEM_100 $RUID_I
 $MITEM_101 $REDIS_I
 $MITEM_102 $GIT_I
 $MITEM_103 $PY_I
 $MITEM_104 $PS_I$PSSRV_I

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MHEADER3
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MITEM_200
 $MITEM_201 ${PHP_[53]}
 $MITEM_202 ${PHP_[54]}
 $MITEM_203 ${PHP_[55]}
 $MITEM_204_CB2 ${PHP_[56]}

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MHEADER4
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 $MITEM_300
 $MITEM_301
 $MITEM_302

$MEXIT"

BLAH2="OS Version : $CENTOS_V
Memory     : $MEMORY
$PHPLINE
$L_MENU"

	TERMSIZE=`stty size |cut -d " " -f2`
	if [ $TERMSIZE -lt 80 ]; then
		COLUMNS=1
	elif [ $TERMSIZE -lt 100 ]; then
		PRINTSIZE="80"
		COLSIZE="40"
		COLUMNS=2
	elif [ $TERMSIZE -ge 100 ]; then
		PRINTSIZE="100"
		COLSIZE="50"
		COLUMNS=2
	fi

	if [ $COLUMNS -eq 2 ]; then
		UNTIME=`date +%s`
		echo -e "$BLAH" >/tmp/$UNTIME"a" && echo -e "$BLAH2" >/tmp/$UNTIME"b"
	
		if ! [ "$REBUILD" == ""  ]; then
			echo -e "$REBUILD" >/tmp/$UNTIME"c"
			fold /tmp/$UNTIME"c" -w $COLSIZE -s >/tmp/$UNTIME"d"
			cat /tmp/$UNTIME"d" >> /tmp/$UNTIME"b"
			rm /tmp/$UNTIME"c" /tmp/$UNTIME"d"
		fi
	
		if ! [ "$COMMENTR" == ""  ]; then
			echo -e "\n\n$COMMENTRA$COMMENTRB$COMMENTR" >/tmp/$UNTIME"c"
			fold /tmp/$UNTIME"c" -w $COLSIZE -s >/tmp/$UNTIME"d"
			cat /tmp/$UNTIME"d" >> /tmp/$UNTIME"b"
			rm /tmp/$UNTIME"c" /tmp/$UNTIME"d"
		fi
	
		pr -o 0 -m -t -w $PRINTSIZE /tmp/$UNTIME"a" /tmp/$UNTIME"b"
		rm /tmp/$UNTIME"a" /tmp/$UNTIME"b"
	else
		echo -e "$BLAH"
	fi
	unset BLAH BLAH2 REBUILD UNTIME COMMENTR COMMENTRA COMMENTRB COLUMNS COLSIZE PRINTSIZE
}

read_options(){
	local choice
	read -p "Enter choice: " choice
	case $choice in
		1) LOG_ACTION="Imagick"
			i_imagick ;;
		2) LOG_ACTION="PDFlib"
			i_pdflib ;;
		3) LOG_ACTION="MailParse"
			i_mailparse ;;
		4) i_memcache ;;
		5) LOG_ACTION="APC"
			i_apc ;;
		6) LOG_ACTION="XSL extension"
			i_xsl ;;
		7) LOG_ACTION="PHP Redis"
			i_phpredis ;;
		8) LOG_ACTION="Zend OPcache"
			i_zendopcache ;;
		9) LOG_ACTION="IMAP extension"
			i_imap ;;
		10) LOG_ACTION="PHP SSH2"
			i_ssh2 ;;
		11) LOG_ACTION="LDAP extension"
			i_ldap ;;
		12) LOG_ACTION="Tidy extension"
			i_tidy ;;
		13) LOG_ACTION="Intl extension"
			i_intl ;;
		100) LOG_ACTION="Mod_ruid2" 
			mod_ruid ;;
		101) redis ;;
		102) git ;;
		103) python_27 ;;
		104) LOG_ACTION="PHP Postgres"
			 postgres ;;
		200) php_update_minor ;;
		201) LOG_ACTION="Upgrade to PHP 5.3" 
			PHP_UPGRADE=5.3
			php_upgrade ;;
		202) LOG_ACTION="Upgrade to PHP 5.4" 
			PHP_UPGRADE=5.4
			php_upgrade ;;
		203) LOG_ACTION="Upgrade to PHP 5.5" 
			PHP_UPGRADE=5.5
			php_upgrade ;;
		204) LOG_ACTION="Upgrade to PHP 5.6" 
			PHP_UPGRADE=5.6
			php_upgrade ;;
		300) mysql_minor ;;
		301) MYSQL_UP=5.5
			MARIADB_UP=10.0
			mysql_upgrade ;;
		302) MYSQL_UP=5.6
			mysql_upgrade ;;
		900) rollback_manual ;;
		x) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
}

while true
do
 
	show_menus
	read_options
done