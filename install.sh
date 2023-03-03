#! /bin/bash

set -e

export $(aws ssm get-parameters --region "us-east-1" --with-decryption --names '/crowdstrike/CS_API_CLIENT_ID' '/crowdstrike/CS_API_CLIENT_SECRET' '/crowdstrike/CLOUDSIM_CID' '/crowdstrike/CLOUDSIM_TAGS' | python -c"import json, sys; print reduce(lambda m, x: \"\n\".join([m, \"%s=%s\" % (x['Name'].split('/')[-1],x['Value'])]), json.loads(sys.stdin.read())['Parameters'], '')")

sudo yum install -y yum-cron binutils yum-plugin-kernel-livepatch kpatch-runtime libnl

# Download falcon download script
curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/download-falcon.py -o /tmp/download-falcon.py

# run download script
python /tmp/download-falcon.py /tmp/falcon-sensor.rpm

# install and configure falcon
sudo yum -y install /tmp/falcon-sensor.rpm
sudo /opt/CrowdStrike/falconctl -s -f --cid=$CLOUDSIM_CID --tags=$CLOUDSIM_TAGS --trace=debug --feature=enableLog --message-log=true

# Overwrite yum-cron.conf sections
sudo sed -i "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
sudo sed -i "s/update_cmd = default/update_cmd = security/" /etc/yum/yum-cron.conf

# enable and start falcon
sudo systemctl enable falcon-sensor.service
sudo systemctl start falcon-sensor.service

# enable and start yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Install and enable live kernel pathcing
sudo yum kernel-livepatch enable -y
sudo amazon-linux-extras enable livepatch
