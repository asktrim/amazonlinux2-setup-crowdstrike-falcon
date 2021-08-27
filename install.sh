#! /bin/bash

set -e

curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/download-falcon.py -o /tmp/download-falcon.py

python /tmp/download-falcon.py /tmp/falcon-sensor.rpm

yum -y install /tmp/falcon-sensor.rpm

/opt/CrowdStrike/falcon-ctl -s -f --cid=$CLOUDSIM_CID

systemctl enable falcon-sensor.service
systemctl start falcon-sensor.service
