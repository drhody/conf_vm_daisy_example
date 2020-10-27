#!/bin/bash

set -e
set -x

sed -i "s#-o '-p -- .*u'#--autologin root#g" /lib/systemd/system/serial-getty@.service
sed -i "s#-o '-p -- .*u'#--autologin root#g" /lib/systemd/system/console-getty.service
sed -i "s#-o '-p -- .*u'#--autologin root#g" /lib/systemd/system/getty@.service

