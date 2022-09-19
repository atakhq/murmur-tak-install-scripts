
echo " "
echo " "
echo "Murmur (Mumble) VOIP Install Script for use with TAK Server CentOs7"
echo "** YOU MUST RUN THIS SCRIPT AS ROOT USER **"
echo " "

read -p "Press any key to begin ..."

sudo yum install bzip2 wget -y

cd tmp
wget https://github.com/mumble-voip/mumble/releases/download/1.2.13/murmur-static_x86-1.2.13.tar.bz2
tar -vxjf ./murmur-static_x86-1.2.13.tar.bz2
sudo mkdir /usr/local/murmur
sudo cp -r ./murmur-static_x86-1.2.13/* /usr/local/murmur/
sudo cp ./murmur-static_x86-1.2.13/murmur.ini /etc/murmur.ini
sudo groupadd -r murmur
sudo useradd -r -g murmur -m -d /var/lib/murmur -s /sbin/nologin murmur
sudo mkdir /var/log/murmur
sudo chown murmur:murmur /var/log/murmur
sudo chmod 0770 /var/log/murmur

echo "If you want to apply a password to your Murmur server to login, enter one now. (leave blank for no pw)"
read PASSWD

echo " "
echo "USING PASSWORD: $PASSWD"
echo " "

#delete old config and make a new one
sudo rm /etc/murmur.ini 
sudo tee /etc/murmur.ini >/dev/null << EOF
# Murmur configuration file.
database=
dbus=session

icesecretwrite=

logfile=/var/log/murmur/murmur.log

pidfile=/var/run/murmur/murmur.pid

# Welcome message sent to clients when they connect.
welcometext="<br />Welcome to this server running <b>Murmur</b>.<br />Enjoy your stay!<br />"

# Port to bind TCP and UDP sockets to.
port=64738

# Password to join server.
serverpassword=$PASSWD

# Maximum bandwidth (in bits per second) clients are allowed to send speech at.
bandwidth=72000

# Maximum number of concurrent clients allowed.
users=100

uname=murmur

# You can configure any of the configuration options for Ice here. We recommend leave the defaults as they are.
# Please note that this section has to be last in the configuration file.

[Ice]
Ice.Warn.UnknownProperties=1
Ice.MessageSizeMax=65536
EOF


#create the service file
sudo tee /etc/systemd/system/murmur.service >/dev/null << EOF
[Unit]
 Description=Mumble Server (Murmur)
 Requires=network-online.target
 After=network-online.target mariadb.service time-sync.target
[Service]
 User=murmur
 Type=forking
 PIDFile=/var/run/murmur/murmur.pid
 ExecStart=/usr/local/murmur/murmur.x86 -ini /etc/murmur.ini
[Install]
 WantedBy=multi-user.target
EOF

#create the config file
sudo tee /etc/tmpfiles.d/murmur.conf >/dev/null << EOF
d /var/run/murmur 775 murmur murmur
EOF

#Now let systemd create the temp files for Murmur and reload the systemd configuration.
sudo systemd-tmpfiles --create /etc/tmpfiles.d/murmur.conf
sudo systemctl daemon-reload

#Enable on boot, start, log status
sudo systemctl enable murmur.service
sudo systemctl start murmur.service
sudo systemctl status murmur.service


echo " "
echo " "
echo "****************************************************************"
echo "Murmur has been installed and should be running (verify above should see green dot and say Active)"
echo "Server Login Password: $PASSWD"
echo "****************************************************************"
echo " "
echo " "
