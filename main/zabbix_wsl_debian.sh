#!/bin/bash

### ZABBIX INSTALLATION FROM SOURCES FOR WINDOWS WSL DEBIAN BASED
### version beta 1
### by diasdm
### https://www.zabbix.com/documentation/current/manual/installation/install

### REQUIREMENTS
#!!-- IF UPGRADING FROM A PACKAGES INSTALLATION, REMOVE ALL ZABBIX PACKAGES FIRST
#!!-- THIS IS AN APACHE2 AND MYSQL/MARIADB INSTALLATION
#!!-- MOST COMMANDS REQUIRE ELEVATED PRIVILEGES, IT IS SUGGESTED TO START THE SCRIPT AS ROOT
#!!-- INTERNET ACCESS IS REQUIRED TO DOWNLOAD ZABBIX AND GO (Go enviroment as well)

### LIMITATIONS
#!!-- MADE FOR DEBIAN BASED WSL DISTRIBUTIONS
#!!-- FOR NEW INSTALLATIONS, ZABBIX DB MUST BE PREVIOUSLY INSTALLED AND CREATED, BUT NOT POPULATED!
#!!-- RE-EXECUTION OF THIS SCRIPT IS CAPABLE OF UPDATING ZABBIX
#!!-- IT IS REQUIRED TO UPDATE MANUALLY ZABBIX AND GO LINKS, AND PHP DIRECTORY, IF THEY ARE CHANGED
#!!-- 						SOME VARIABLES ARE PROVIDED FOR THAT
#!!-- WHATCH FOR "/opt" CLUTTERING


### 001.000 OS ENVIROMENT - START

### 001.999 ERROR CHECKING
	function error_check() {
		if [ "$RETURN" -ne "0" ]; then
			echo -e "\nERROR $1 - ($RETURN)\n"
			exit 99
		fi; }

### 001.001 CLEAR AND MESSAGE
	function clear_msg() { clear; echo -e "$1\n"; sleep 2; }

### 001.002 VARIABLES
ZBXDIR="/opt"                                   # ZABBIX SOURCES DOWNLOAD DIR
ZBXVER="zabbix-6.0.9"                           # ZABBIX VERSION
ZBXVERDIR="6.0"                                 # ZABBIX REPOSITORY DIR WITHIN DOWNLOAD LINK
ZBXCONF_SV="/usr/local/etc/zabbix_server.conf"  # ZABBIX DEFAULT SERVER CONFIGURATION PATH
ZBXCONF_AG="/usr/local/etc/zabbix_agentd.conf"  # ZABBIX DEFAULT AGENT CONFIGURATION PATH

GODIR="/opt"                                    # GO DOWNLOAD DIR
GOVER="go1.19.1"                                # GO VERSION
PHPINI="/etc/php/*/apache2/php.ini"		# PHP DEFAULT CONFIGURATION FILE

### 001.003 COLLECTING ZABBIX DB CONFIGURATION
clear_msg "ZABBIX SERVER DB CONFIGURATION..."

echo -e "PLEASE, PROVIDE YOUR ZABBIX DATABASE CONFIGURATION.
LEAVE BLANK TO USE DEFAULT.\n"

read -p "DB HOSTNAME/IP (default \"localhost\"): " DBHOST
read -p "DB NAME (default \"zabbix\"): " DBNAME
read -p "DB USER (default \"zabbix\"): " DBUSER
read -p "DB PASSWORD (default \"zabbix\"): " DBPASS

[ -z ${DBHOST} ] && DBHOST="localhost"
[ -z ${DBNAME} ] && DBNAME="zabbix"
[ -z ${DBUSER} ] && DBUSER="zabbix"
[ -z ${DBPASS} ] && DBPASS="zabbix"

### 001.004 UPDATING SYSTEM
clear_msg "PREPARING OS..."

apt-get -y update && sudo apt-get -y upgrade
apt-get -y install wget openssh-server make tcpdump netcat net-tools traceroute mariadb-client # default-mysql-client
	RETURN=$?; error_check "001.004"

### 001.005 CHECK IF ZABBIX DB EXISTS
if [ -z "$(mysql -NB -h${DBHOST} -u${DBUSER} -p${DBPASS} -e "SHOW DATABASES LIKE '${DBNAME}';")" ]; then 
	RETURN=1; error_check "001.004 - ZABBIX DATABASE WAS NOT FOUND OR ACCESS IS INVALID"
fi

pkill zabbix_server
pkill zabbix_agent

### 001.000 OS ENVIROMENT - END


### 002.000 ZABBIX DOWNLOAD - START
clear_msg "DOWNLOADING ZABBIX SOURCES..."

wget -nc -O $ZBXDIR/$ZBXVER.tar.gz https://cdn.zabbix.com/zabbix/sources/stable/$ZBXVERDIR/$ZBXVER.tar.gz
tar --skip-old-files -C $ZBXDIR/ -xzvf $ZBXDIR/$ZBXVER.tar.gz
	RETURN=$?; error_check "002.001"
### 002.000 ZABBIX DOWNLOAD - END


### 003.000 GO INSTALL - START
### https://go.dev/doc/install
### USER ROOT IS REQUIRED
clear_msg "DOWNLOADING AND INSTALLING GO..."

wget -nc -O $GODIR/$GOVER.linux-amd64.tar.gz https://go.dev/dl/$GOVER.linux-amd64.tar.gz
rm -rf /usr/local/go && tar --skip-old-files -C /usr/local -xzvf $GODIR/$GOVER.linux-amd64.tar.gz
	RETURN=$?; error_check "003.001"

if [ -z `grep -e 'export PATH=$PATH:/usr/local/go/bin' /etc/profile` ]; then
	echo -e "\n# GO PATH" >> /etc/profile
	echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
		RETURN=$?; error_check "003.002 - You need to be \"root\""
	source /etc/profile
fi

### 003.000 GO INSTALL - END


### 004.000 ZABBIX DB SCHEMA - START
clear_msg "CREATING ZABBIX DB SCHEMA... PLEASE WAIT"

if [ -z "$(mysql -NB -h${DBHOST} -u${DBUSER} -p${DBPASS} ${DBNAME} -e "SHOW TABLES;")" ]; then
	mysql -h${DBHOST} -u${DBUSER} -p${DBPASS} ${DBNAME} < $ZBXDIR/$ZBXVER/database/mysql/schema.sql
		RETURN=$?; error_check "004.001"
	mysql -h${DBHOST} -u${DBUSER} -p${DBPASS} ${DBNAME} < $ZBXDIR/$ZBXVER/database/mysql/images.sql
		RETURN=$?; error_check "004.002"
	mysql -h${DBHOST} -u${DBUSER} -p${DBPASS} ${DBNAME} < $ZBXDIR/$ZBXVER/database/mysql/data.sql
		RETURN=$?; error_check "004.003"
else
	echo -e "\nZABBIX DB IS POPULATED - NO CHANGES MADE\n"; sleep 3;
fi
### 004.000 ZABBIX DB SCHEMA - END


### 005.000 PHP DEPENDENCIES AND APACHE2 INSTALLATION - START
clear_msg "INSTALLING APACHE2 AND PHP..."

apt-get install -y apache2 php php-mysql php-gd php-curl php-bcmath php-mbstring php-xml php-ldap
	RETURN=$?; error_check "005.001"
#php-opcache php-mcrypt php-mysqlnd
### 005.000 PHP DEPENDENCIES - END


### 006.000 ZABBIX SOURCES DEPENDENCIES - START
clear_msg "INSTALLING ZABBIX DEPENDENCIES..."

apt-get install -y gcc default-libmysqlclient-dev libxml2 libxml2-dev libevent-dev pkg-config snmp libsnmp-dev libssh2-1-dev libldap2-dev libcurl4-openssl-dev libpcre3-dev unixodbc-dev libopenipmi-dev default-jdk-headless
	RETURN=$?; error_check "006.001"
### 006.000 ZABBIX SOURCES DEPENDENCIES - END


### 007.000 ZABBIX USER - START
clear_msg "CREATING ZABBIX USER..."

if [ $(getent group zabbix) ]; then
	echo -e "\n007.001 - ZABBIX GROUP ALREADY EXISTS\n"; sleep 3;
else
	groupadd --system zabbix
fi

if [ $(id -nu zabbix) ]; then
	echo -e "\n007.002 - ZABBIX USER ALREADY EXISTS\n"; sleep 3;
else
	useradd --system -g zabbix -d /usr/lib/zabbix -s /sbin/nologin -c "Zabbix Monitoring System" zabbix
fi
### 007.000 ZABBIX USER - END


### 008.000 ZABBIX SOURCES INSTALL - START
### CHOOSE YOUR ZABBIX FUNCTIONALITIES HERE
### IF YOU DO/DON'T NEED DIFFERENT OPTIONS, ADD/REMOVE IT TO THE LINE BELLOW. SEE "./configure --help"
clear_msg "CONFIGURING ZABBIX INSTALLATION..."

cd $ZBXDIR/$ZBXVER/
./configure --enable-server \
	    --enable-agent \
	    --enable-agent2 \
	    --enable-webservice \
	    --enable-java \
	    --enable-ipv6 \
	    --with-mysql \
	    --with-unixodbc \
	    --with-openipmi \
	    --with-net-snmp \
	    --with-libcurl \
	    --with-libxml2 \
	    --with-openssl \
	    --with-ldap \
	    --with-ssh2
	RETURN=$?; error_check "008.001 - Configuration error. Check \"$ZBXDIR/$ZBXVER/config.log\"."

clear_msg "COMPILING ZABBIX..."

make install
	RETURN=$?; error_check "008.002 - Installation error."
### 008.000 ZABBIX SOURCES INSTALL - END


### 009.000 ZABBIX FRONTEND CONFIGURATION
clear_msg "CONFIGURING ZABBIX FRONTEND..."

mkdir -p /var/www/html/zabbix/
	RETURN=$?; error_check "009.001"
rsync -av $ZBXDIR/$ZBXVER/ui/* /var/www/html/zabbix/
	RETURN=$?; error_check "009.002"
chown -R www-data:www-data /var/www/html/zabbix/
	RETURN=$?; error_check "009.003"

sed -i 's|post_max_size = 8M|post_max_size = 16M|' $PHPINI
sed -i 's|max_execution_time = 30|max_execution_time = 300|' $PHPINI
sed -i 's|max_input_time = 60|max_input_time = 300|' $PHPINI

service apache2 restart
	RETURN=$?; error_check "009.005"
### 009.000 ZABBIX FRONTEND CONFIGURATION - END


### 010.000 ZABBIX SERVER CONFIGURATION - START
clear_msg "AJUSTING ZABBIX SERVER CONFIGURATION FILE..."

rsync -av $ZBXDIR/$ZBXVER/conf/zabbix_server.conf $ZBXCONF_SV

sed -i 's|^LogFile=\/tmp\/zabbix_server.log|#LogFile=\/tmp\/zabbix_server.log|' $ZBXCONF_SV
sed -i "s|^DBName=zabbix|#DBName=zabbix|" $ZBXCONF_SV
sed -i 's|^DBUser=zabbix|#DBUser=zabbix|' $ZBXCONF_SV
sed -i 's|^Timeout=4|#Timeout=4|' $ZBXCONF_SV
sed -i 's|^LogSlowQueries=3000|#LogSlowQueries=3000|' $ZBXCONF_SV
sed -i 's|^StatsAllowedIP=127.0.0.1|#StatsAllowedIP=127.0.0.1|' $ZBXCONF_SV
sed -i 's|^# Include=/usr/local/etc/zabbix_server.conf.d/\*\.conf|Include=/usr/local/etc/zabbix_server.conf.d/\*\.conf|' $ZBXCONF_SV

if [ -e $ZBXCONF_SV.d/zabbix_server_auto.conf ]; then
	echo -e "\n\nATENTION - 010.001 - AUTO SERVER CONFIGURATION FILE EXISTS. NO CHANGES MADE"
	echo -e "PLEASE REVIEW YOUR DEFAULT SERVER CONFIGURATION FILE IF UPDATING.\n\n"
	sleep 5
else
	cat > $ZBXCONF_SV.d/zabbix_server_auto.conf <<- EOF
		### ZABBIX SOURCES AUTOMATED INSTALLATION SCRIPT FOR WSL ###
		### by diasdm ###
		### https://github.com/diasdmhub/ ###

		LogFile=/tmp/zabbix_server.log
		LogFileSize=50
		DBHost=${DBHOST}
		DBName=${DBNAME}
		DBUser=${DBUSER}
		DBPassword=${DBPASS}
		Timeout=4
		LogSlowQueries=3000
		StatsAllowedIP=127.0.0.1
		StartReportWriters=1
		SNMPTrapperFile=/tmp/zabbix_traps.tmp
		StartSNMPTrapper=1
		StartVMwareCollectors=1
	EOF
fi
	RETURN=$?; error_check "010.001"
### 010.000 ZABBIX SERVER CONFIGURATION - END


### 011.000 ZABBIX AGENT CONFIGURATION - START
clear_msg "AJUSTING ZABBIX AGENT CONFIGURATION FILE..."

rsync -av $ZBXDIR/$ZBXVER/conf/zabbix_agentd.conf $ZBXCONF_AG

sed -i 's|^LogFile=/tmp/zabbix_agentd.log|#LogFile=/tmp/zabbix_agentd.log|' $ZBXCONF_AG
sed -i 's|^Server=127.0.0.1|#Server=127.0.0.1|' $ZBXCONF_AG
sed -i 's|^ServerActive=127.0.0.1|#ServerActive=127.0.0.1|' $ZBXCONF_AG
sed -i 's|^Hostname=Zabbix\ server|#Hostname=Zabbix\ server|' $ZBXCONF_AG
sed -i 's|^# Include=/usr/local/etc/zabbix_agentd.conf.d/\*\.conf|Include=/usr/local/etc/zabbix_agentd.conf.d/\*\.conf|' $ZBXCONF_AG

if [ -e $ZBXCONF_AG.d/zabbix_agent_auto.conf ]; then
	echo -e "ATENTION - 011.001 - AUTO AGENT CONFIGURATION FILE EXISTS. NO CHANGES MADE"
	echo -e "PLEASE REVIEW YOUR DEFAULT AGENT CONFIGURATION FILE IF UPDATING.\n\n"
	sleep 5
else
	cat > $ZBXCONF_AG.d/zabbix_agent_auto.conf <<- EOF
		### ZABBIX SOURCES AUTOMATED INSTALLATION SCRIPT FOR WSL ###
		### by diasdm ###
		### https://github.com/diasdmhub/ ###

		LogFile=/tmp/zabbix_agentd.log
		LogFileSize=10
		Server=127.0.0.1
		Hostname=$HOSTNAME
	EOF
		RETURN=$?; error_check "011.001"
fi
### 011.000 ZABBIX AGENT CONFIGURATION - END


### 012.000 ZABBIX BACKGROUND START - START
clear_msg "STARTING ZABBIX..."

zabbix_server -c $ZBXCONF_SV
	RETURN=$?; error_check "012.001 - ZABBIX SERVER START FAILED"
zabbix_agentd -c $ZBXCONF_AG
	RETURN=$?; error_check "012.002 - ZABBIX AGENT START FAILED"
### 012.000 ZABBIX BACKGROUND START - END


### DOWNLOAD FRONTEND CONFIG IF IT FAILS THEN COPY IT TO YOUR SERVER
clear_msg "ZABBIX INSTALLTION FINISHED\n\nPROCEED TO ZABBIX WEB UI\nhttp://$(hostname -I | xargs)/zabbix"

#mv ~/zabbix.conf.php /var/www/html/zabbix/conf/zabbix.conf.php
#systemctl restart httpd
