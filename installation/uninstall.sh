#!/bin/bash
set -e

python3.10 -m pip uninstall bacnet_client
rm -r /nuk/.packages/*
rm /var/lib/bacnet_client/mongodb.pem

# Uncomment line below to remove installation debian packages.
# apt remove software-properties-common inotify-tools python3-pip curl jq
