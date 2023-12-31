#!/bin/bash
# modified for cloudron - Samir Saidani
################################################################################
# Script for installing Odoo V10 on Ubuntu 16.04, 15.04, 14.04 (could be used for other version too)
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 14.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################
##fixed parameters
#odoo
OE_USER="odoo"
#OE_HOME="/app/code/$OE_USER"
OE_HOME="/app/code"
OE_HOME_EXT="$OE_HOME/${OE_USER}-server"
#The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
#Choose the Odoo version which you want to install. For example: 10.0, 9.0, 8.0, 7.0 or saas-6. When using 'trunk' the master version will be installed.
#IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 10.0
OE_VERSION="10.0"
# Set this to True if you want to install Odoo 10 Enterprise!
IS_ENTERPRISE="False"
#set the superadmin password
OE_SUPERADMIN="admin"
OE_CONFIG="${OE_USER}"

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
#WKHTMLTOX_X64=http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb
#WKHTMLTOX_X32=http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-i386.deb
WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb
WKHTMLTOX_X32=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-i386.deb

## Package libjpeg62-turbo need to be install from debian sid on ubuntu xenial 16.04
LIBJPEG62_X64=http://ftp.fr.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.2-2+b1_amd64.deb
LIBJPEG62_X32=http://ftp.fr.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.2-2+b1_i386.deb


## Installing extra-modules
SERVER_TOOLS=https://github.com/OCA/server-tools


#--------------------------------------------------
# Install pip2 for python2
# We need to install pip2 in order to pip install passlib
# see https://github.com/odoo/odoo/issues/16451
#--------------------------------------------------

echo -e "\n---- Install pip2 ----"
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python2 get-pip.py


#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-mark hold postfix phpmyadmin
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
#echo -e "\n---- Install PostgreSQL Server ----"
#sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget git python-pip gdebi-core -y
	
echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y python-suds
	
echo -e "\n---- Upgrade pip ----"
pip install --upgrade pip 

echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen ofxparse XlsxWriter

echo -e "\n---- Install python packages/requirements ----"
sudo pip install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 10 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url_wkhtml=$WKHTMLTOX_X64
      _url_libjpeg=$LIBJPEG62_X64
  else
      _url_wkhtml=$WKHTMLTOX_X32
      _url_libjpeg=$LIBJPEG62_X32
  fi
  sudo wget $_url_wkhtml
  sudo wget $_url_libjpeg
  sudo gdebi --n `basename $_url_libjpeg`
  sudo gdebi --n `basename $_url_wkhtml`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
	
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo
sudo chown -R $OE_USER:$OE_USER /app/code
sudo chown -R $OE_USER:$OE_USER /app/data

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    echo -e "\n---- Adding Enterprise code under $OE_HOME/enterprise/addons ----"
    sudo git clone --depth 1 --branch 10.0 https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons"

    echo -e "\n---- Installing Enterprise specific libraries ----"
    sudo apt-get install nodejs npm
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
else
    echo -e "\n---- Create custom module directory ----"
#    sudo su $OE_USER -c "mkdir $OE_HOME/custom"
#    sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"
    sudo su $OE_USER -c "mkdir $OE_HOME/extra-addons"
fi

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"
#sudo cp $OE_HOME_EXT/debian/odoo.conf /app/data/${OE_CONFIG}.conf
sudo su $OE_USER -c "echo '[options]' >> /app/data/${OE_CONFIG}.conf"
sudo chown $OE_USER:$OE_USER /app/data/${OE_CONFIG}.conf
sudo chmod 640 /app/data/${OE_CONFIG}.conf

echo -e "* Change server config file"
sudo sed -i s/"db_user = .*"/"db_user = $OE_USER"/g /app/data/${OE_CONFIG}.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /app/data/${OE_CONFIG}.conf
sudo su root -c "echo '[options]' > /app/data/${OE_CONFIG}.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /app/data/${OE_CONFIG}.conf"
if [  $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "echo 'addons_path=$OE_HOME/enterprise/addons,$OE_HOME_EXT/addons' >> /app/data/${OE_CONFIG}.conf"
else
#    sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/${OE_CONFIG}.conf"
    sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/extra-addons,/app/data/addons/server-tools' >> /app/data/${OE_CONFIG}.conf"
fi

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start-odoo.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/app/data/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start-odoo.sh"
sudo chmod 755 $OE_HOME_EXT/start-odoo.sh


#--------------------------------------------------
# Install ODOO ADDONS
#--------------------------------------------------
echo -e "\n==== Installing ODOO ADDONS ===="

echo -e "\n---- Install python libraries ----"
sudo pip install python-ldap unidecode acme_tiny IPy email_validator pyotp pysftp fdb sqlalchemy raven checksumdir python-stdnum pyopenssl odoorpc

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir /app/data/addons/server-tools"

sudo git clone --depth 1 --branch 10.0 $SERVER_TOOLS "/app/data/addons/server-tools"

echo -e "\n---- Setting permissions on addons folder ----"
sudo chown -R $OE_USER:$OE_USER /app/data/addons/*



#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG

# Specify the user name (Default: odoo).
USER=$OE_USER

# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/app/data/${OE_CONFIG}.conf"

# pidfile
PIDFILE=/var/run/\${NAME}.pid

# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}

case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;

restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;

esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $OE_PORT' >> /app/data/${OE_CONFIG}.conf"

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_HOME/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"

# ajout de librairies python pour projet MAIE (module sale_order_import_csv)
sudo pip install PyPDF2 unicodecsv
