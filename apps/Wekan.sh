#!/bin/sh

[ $1 = update ] && { systemctl stop wekan; rm -rf /home/wekan/bundle; }
[ $1 = remove ] && { sh sysutils/service.sh remove Wekan; userdel -r wekan; whitpail --msgbox "Wekan removed!" 8 32; exit; }

# https://github.com/wekan/wekan/wiki/Install-and-Update
# Define port
port=$(whiptail --title "Wekan port" --inputbox "Set a port number for Wekan" 8 48 "8081" 3>&1 1>&2 2>&3)


[ $1 = install ] && { . $DIR/sysutils/MongoDB.sh; }

# https://github.com/4commerce-technologies-AG/meteor
# Special Meteor + Node.js bundle for ARM
[ $ARCHf = arm ] && [ $1 = install ] && { . $DIR/sysutils/Meteor.sh; }

# Add wekan user
useradd -m wekan

# Go to wekan user directory
cd /home/wekan

# Get the latest Wekan release
ver=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/wekan/wekan/releases/latest)

# Only keep the version number in the url
ver=${ver#*v}

# Download the arcive
wget "https://github.com/wekan/wekan/releases/download/v$ver/wekan-$ver.tar.gz" 2>&1 | \
stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | whiptail --gauge "Downloading the Wekan archive..." 6 64 0

# Extract the downloaded archive and remove it
(pv -n wekan-$ver.tar.gz | tar xzf -) 2>&1 | whiptail --gauge "Extracting the files from the archive..." 6 64 0

mv bundle Wekan
rm wekan-$ver.tar.gz

if [ $ARCHf = arm ] ;then
  $install python make g++

  # Reinstall bcrypt and bson to a newer version is needed
  cd /home/wekan/Wekan/programs/server/npm/npm-bcrypt && /usr/share/meteor/dev_bundle/bin/npm uninstall bcrypt && /usr/share/meteor/dev_bundle/bin/npm install bcrypt
  cd /home/wekan/Wekan/programs/server/npm/cfs_gridfs/node_modules/mongodb && /usr/share/meteor/dev_bundle/bin/npm uninstall bson && /usr/share/meteor/dev_bundle/bin/npm install bson
elif [ $ARCHf = x86 ] ;then
  $install graphicsmagick

  # Meteor needs Node.js 0.10.45
  wget https://Node.js.org/dist/v0.10.45/node-v0.10.45-linux-x64.tar.gz 2>&1 | \
  stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | whiptail --gauge "Downloading the Node.js 0.10.45 archive..." 6 64 0

  # Extract the downloaded archive and remove it
  (pv -n node-v0.10.45-linux-x64.tar.gz | tar xzf - -C /usr/local/share) 2>&1 | whiptail --gauge "Extracting the files from the archive..." 6 64 0
  rm node-v0.10.45-linux-x64.tar.gz
else
    whiptail --msgbox "Your architecture $ARCHf isn't supported" 8 48
fi

# Move to the server directory and install the dependencies:
cd /home/wekan/Wekan/programs/server

[ $ARCHf = x86 ] && /usr/local/share/node-v0.10.45-linux-x64/bin/npm install
[ $ARCHf = arm ] && /usr/share/meteor/dev_bundle/bin/npm install

# Change the owner from root to wekan
chown -R wekan /home/wekan

[ $ARCHf = x86 ] && node=/usr/local/share/node-v0.10.45-linux-x64/bin/node
[ $ARCHf = arm ] && node=/usr/share/meteor/dev_bundle/bin/node

# Create the SystemD service
cat > "/etc/systemd/system/wekan.service" <<EOF
[Unit]
Description=Wekan Server
Wants=mongod.service
After=network.target mongod.service
[Service]
Type=simple
WorkingDirectory=/home/wekan/Wekan
ExecStart=$node main.js
Environment=MONGO_URL=mongodb://127.0.0.1:27017/wekan
Environment=ROOT_URL=http://$IP:$port/ PORT=$port
User=wekan
Restart=always
[Install]
WantedBy=multi-user.target
EOF

# Start the service and enable it to start on boot
systemctl start wekan
systemctl enable wekan

[ $1 = install ] && state=installed || state=$1d
whiptail --msgbox "Wekan $state!

Open http://$URL:$port in your browser" 10 64
