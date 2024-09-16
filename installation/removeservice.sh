#!/bin/bash
set -e

systemctl disable bacnet_client
systemctl stop bacnet_client
systemctl daemon-reload

rm /etc/systemd/system/bacnet_client.service

# Uncomment line below to remove installation debian packages.
# apt remove software-properties-common inotify-tools python3-pip curl jq
