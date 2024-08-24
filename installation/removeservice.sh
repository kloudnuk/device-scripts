#!/bin/bash
set -e

systemctl disable bacnet_client
systemctl stop bacnet_client
systemctl daemon-reload

rm /etc/systemd/system/bacnet_client.service
