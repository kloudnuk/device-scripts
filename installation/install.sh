#!/bin/bash

#### MAKE SURE TO UPDATE APT AND DOWNLOAD REQUIRED APT PACKAGES BEFORE RUNNING SCRIPT ####

apt update && apt upgrade -y
apt install -y software-properties-common inotify-tools \
    python3-pip curl jq

set -e

function update_config { # file section option value
    file=$1
    section=$2
    option=$3
    value=$4
    echo "updating $file"
    if grep -q "^\[$section\]" "$file"; then
        echo current: $(awk 'BEGIN{FS="="} NR==3{print $1 $2}' "$file")
        sed -i -E "/^\[$section\]/,/^\[/ s/^(${option}[[:space:]]*=[[:space:]]*).*/\1\"${value}\"/" "$file"
        echo new: $(awk 'BEGIN{FS="="} NR==3{print $1 $2}' "$file")
    else
        echo "Section $section not found in $file."
    fi
}

devicename=$1
orgname=$2
username=$3
password=$4
version=0.0.10

[[ -z $devicename ]] && devicename="$(read -rp 'enter a device name: ')"
[[ -z $orgname ]] && orgname="$(read -r -p 'enter an organization name: ')"
[[ -z $username ]] && username="$(read -r -p 'enter user name: ')"
[[ -z $password ]] && password="$(read -r -p 'enter password: ' -s)"
echo -e "\n"
auth="$(echo -n $username':'$password | base64)"

[[ ! -d '/nuk/.packages' ]] && mkdir -p /nuk/.packages
[[ ! -d '/var/lib/bacnet_client' ]] && mkdir /var/lib/bacnet_client

ethif=$(nmcli dev | grep -E 'ethernet.+connected' | awk '{print $1}')
ethaddr=$(ip a | grep -E "inet.*$ethif" | awk '{print $2}')
macaddr=$(cat /sys/class/net/"$ethif"/address)
gtwaddr=$(ip route | grep default | awk '{print $3}')

uuidp1=$(sed 's/\(........\)\(..\)\(..\)\(....\)/\1-\2\3-\4/' \
    /sys/firmware/devicetree/base/serial-number)
uuidp2=$(blkid | grep /dev/mmcblk0 | awk '{print $2}' |
    awk -F '-' '{print "-"$4"-"$5}' | sed 's/.$//')
nukid="$(echo ${uuidp1}${uuidp2})"

curl -X POST --write-out '%{http_code}\n' \
    --location "https://kloudnuk.com/api/v1/devices/enroll?org=$orgname" \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Basic '"$auth" \
    --data "[{ \"controllerid\": \"$nukid\", \
               \"name\": \"$devicename\", \
               \"description\": \"\", \
               \"ipaddress\": \"$ethaddr\", \
               \"macaddress\": \"$macaddr\", \
               \"status\": \"INACTIVE\", \
               \"gateway\": \"$gtwaddr\", \
               \"wgaddress\": \"0.0.0.0\"}]"

if [ $? -eq 0 ]; then

    curl -X POST --write-out '%{http_code}\n' \
        --location "https://kloudnuk.com/api/v1/devices/activate?softwarePackage=bacnet-client_$version.zip&deviceid=$nukid&org=$orgname" \
        --header 'Authorization: Basic '"$auth" \
        --output '/nuk/.packages/bacnet_client.zip'

    [[ ! -d '/nuk/.packages/bacnet_client' ]] &&
        mkdir -p /nuk/.packages/bacnet_client

    unzip /nuk/.packages/bacnet_client.zip -d /nuk/.packages/bacnet_client
    rm /nuk/.packages/bacnet_client.zip

    bacnet_client="$(ls /nuk/.packages/bacnet_client/dist | grep 'bacnet')"
    python3.10 -m pip install /nuk/.packages/bacnet_client/dist/"$bacnet_client"

    ini=/nuk/.packages/bacnet_client/dist/res/local-device.ini

    update_config "$ini" 'device' 'nukid' "$nukid"
    update_config "$ini" 'device' 'tz' 'America/New_York' # Default
    update_config "$ini" 'device' 'loglevel' 'NOTSET'     # Default
    update_config "$ini" 'network' 'interface' "$ethif"
    update_config "$ini" 'mongodb' 'dbname' "$orgname"
    update_config "$ini" 'mongodb' 'connectionstring' 'mongodb+srv://cluster0.cylypox.mongodb.net/?authSource=%24external&authMechanism=MONGODB-X509&retryWrites=true&w=majority&appName=Cluster0'

    mv /nuk/.packages/bacnet_client/cert.pem /var/lib/bacnet_client/mongodb.pem 

else
    echo "Error... $?"
    exit 1
fi
