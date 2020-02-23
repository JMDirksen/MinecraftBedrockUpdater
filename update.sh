#!/bin/bash
cd "$(dirname "$0")"

# Check servername parameter
[ -z $1 ] && echo Missing parameter 'servername' && exit 2
servername=${1%/}

# Init
timestamp=$(date +%y%m%d%H%M%S)
backup=backup-$servername-$timestamp
tty -s && output=1 || output=

# Get latest version
[ $output ] && echo Checking latest version...
url=$(wget -qO- https://www.minecraft.net/en-us/download/server/bedrock/ | grep -o "http.*bin-linux.*\.zip")
version=$(echo $url | grep -oP "\d*\.\d*\.\d*\.\d*")
file=bedrock-server-$version.zip
[ $output ] && echo Latest version: $version

# Installed version
installed=$(cat $servername/version.txt)
[ $output ] && echo Installed version: $installed

# Check if already on newest version
if [ "$version" == "$installed" ]; then
  [ $output ] && echo Up-to-date
  exit
fi

# Stop server
[ $output ] && echo Stopping server...
screen -S $servername -p 0 -X stuff "stop^M"
[ $? -eq 0 ] && sleep 5s

# Backup files
[ $output ] && echo Creating backup...
mv $servername/ $backup/

# New vesion
if [ ! -f "$file" ]; then
  [ $output ] && echo Downloading new version...
  wget -q $url
fi
[ $output ] && echo Extracting server...
unzip -q $file -d $servername

# Restore world & config
[ $output ] && echo Configuring...
cp -r $backup/worlds $backup/server.properties $backup/permissions.json $servername/

# Register version
echo $version > $servername/version.txt

# Start server
[ $output ] && echo Starting server...
pushd $servername > /dev/null
screen -dmS $servername ./bedrock_server
popd > /dev/null
echo Updated $servername to version $version
