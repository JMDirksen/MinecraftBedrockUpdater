#!/bin/bash
cd "$(dirname "$0")"

# Init
servername=${PWD##*/}
timestamp=$(date +%y%m%d%H%M%S)
tty -s && output=1 || output=

# Get latest version
[ $output ] && echo Checking latest version...
url=$(wget -qO- https://www.minecraft.net/en-us/download/server/bedrock/ | grep -o "http.*bin-linux.*\.zip")
version=$(echo $url | grep -oP "\d*\.\d*\.\d*\.\d*")
file=bedrock-server-$version.zip
[ $output ] && echo Latest version: $version

# Installed version
installed=$(cat version.txt)
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
cp server.properties server.properties.bak
cp permissions.json permissions.json.bak
backupfile=backup-$servername-$(date +%y%m%d%H%M%S).tar.gz
tar -zcf ../$backupfile .

# New vesion
if [ ! -f "$file" ]; then
  [ $output ] && echo Downloading new version...
  wget -q $url
fi
[ $output ] && echo Extracting server...
unzip -oq $file

# Restore config
[ $output ] && echo Configuring...
cp server.properties.bak server.properties
cp permissions.json.bak permissions.json

# Register version
echo $version > version.txt

# Start server
[ $output ] && echo Starting server...
screen -dmSL $servername ./bedrock_server
echo Updated $servername to version $version
