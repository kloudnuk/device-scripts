#!/bin/bash
set -e

python3.10 -m pip uninstall bacnet_client
rm -r "$HOME/nuk/"
