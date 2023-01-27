#! /bin/bash

set -e

export $(aws ssm get-parameters --region "us-east-1" --with-decryption --names '/crowdstrike/CS_API_CLIENT_ID' '/crowdstrike/CS_API_CLIENT_SECRET' '/crowdstrike/CLOUDSIM_CID' '/crowdstrike/CLOUDSIM_TAGS' | python -c"import json, sys; print reduce(lambda m, x: \"\n\".join([m, \"%s=%s\" % (x['Name'].split('/')[-1],x['Value'])]), json.loads(sys.stdin.read())['Parameters'], '')")

sudo yum install -y yum-cron

curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/download-falcon.py -o /tmp/download-falcon.py
# Overwrite yum-cron.conf sections
sudo sed -i "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
sudo sed -i "s/update_cmd = default/update_cmd = security/" /etc/yum/yum-cron.conf

python /tmp/download-falcon.py /tmp/falcon-sensor.rpm

sudo yum -y install /tmp/falcon-sensor.rpm

sudo /opt/CrowdStrike/falconctl -s -f --cid=$CLOUDSIM_CID --tags=$CLOUDSIM_TAGS --trace=debug --feature=enableLog --message-log=true

sudo systemctl enable falcon-sensor.service
sudo systemctl start falcon-sensor.service
sudo service yum-cron start
sudo systemctl enable yum-cron
