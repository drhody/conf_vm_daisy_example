#!/bin/bash

set -e
set -x

# Disable apt-daily service and its friends
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer
