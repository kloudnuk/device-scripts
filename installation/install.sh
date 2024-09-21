#!/bin/bash

#set -e

function update_config() {
    local file="$1"
    local section="$2"
    local key="$3"
    local new_value="$4"

    # Use sed to find the section and update the key's value
    sed -i "/^\[$section\]/,/^\[/ s/^\($key *= *\).*/\1\"$new_value\"/" "$file"
}

devicename=$1
orgname=$2
username=$3
password=$4

version=0.0.13
interpreter=python3.10

[[ -z $devicename ]] && devicename="$(read -rp 'enter a device name: ')"
[[ -z $orgname ]] && orgname="$(read -r -p 'enter an organization name: ')"
[[ -z $username ]] && username="$(read -r -p 'enter user name: ')"
[[ -z $password ]] && password="$(read -r -p 'enter password: ' -s)"
echo -e "\n"

[[ ! -d "$HOME/nuk/" ]] && mkdir -p "$HOME/nuk/.packages"

auth="$(echo -n $username':'$password | base64)"
ethif=$(nmcli dev | grep -E 'ethernet.+connected' | awk '{print $1}')
ethaddr=$(ip a | grep -E "inet.*$ethif" | awk '{print $2}')
macaddr=$(cat /sys/class/net/"$ethif"/address)
gtwaddr=$(ip route | grep default | awk '{print $3}')

uuidp1=$(sed 's/\(........\)\(..\)\(..\)\(....\)/\1-\2\3-\4/' \
    /sys/firmware/devicetree/base/serial-number)
uuidp2=$(blkid | grep /dev/mmcblk0 | awk '{print $2}' |
    awk -F '-' '{print "-"$4"-"$5}' | sed 's/.$//')
nukid="$(echo ${uuidp1}${uuidp2})"

echo $devicename
echo $orgname
echo $nukid
echo $ethif
echo $ethaddr
echo $macaddr

curl -X POST --write-out '%{http_code}\n' \
    --location "https://kloudnuk.com/api/v1/devices/enroll?org=${orgname}" \
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

    [[ ! -d "$HOME/nuk/.packages/bacnet_client" ]] &&
        mkdir -p "$HOME/nuk/.packages/bacnet_client"

    curl -X POST --write-out '%{http_code}\n' \
        --location "https://kloudnuk.com/api/v1/devices/activate?softwarePackage=bacnet-client_$version.zip&deviceid=$nukid&org=${orgname}" \
        --header 'Authorization: Basic '"$auth" \
        --output "$HOME/nuk/.packages/bacnet_client.zip"

    unzip "$HOME/nuk/.packages/bacnet_client.zip" -d "$HOME/nuk/.packages/bacnet_client"
    rm "$HOME/nuk/.packages/bacnet_client.zip"

    bacnet_client="$(ls "$HOME/nuk/.packages/bacnet_client/dist" | grep 'bacnet')"
    python3.10 -m pip install "$HOME/nuk/.packages/bacnet_client/dist/$bacnet_client"

    ini="$HOME/nuk/.packages/bacnet_client/dist/res/local-device.ini"

    update_config "$ini" 'device' 'nukid' "$nukid"
    update_config "$ini" 'device' 'label' "$devicename"
    update_config "$ini" 'device' 'tz' "America/New_York"
    update_config "$ini" 'device' 'loglevel' "DEBUG"
    update_config "$ini" 'network' 'interface' "$ethif"
    update_config "$ini" 'mongodb' 'certpath' "$HOME/nuk/.packages/bacnet_client/cert.pem"
    update_config "$ini" 'mongodb' 'dbname' "$orgname"
    update_config "$ini" 'mongodb' 'connectionstring' "mongodb+srv://cluster0.cylypox.mongodb.net/?authSource=%24external&authMechanism=MONGODB-X509&retryWrites=true&w=majority&appName=Cluster0"


else
    echo "Error... $?"
    exit 1
fi
