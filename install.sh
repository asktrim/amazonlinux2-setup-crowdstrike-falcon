#! /bin/bash

set -e

export $(aws ssm get-parameters --region "us-east-1" --with-decryption --names '/crowdstrike/CS_API_CLIENT_ID' '/crowdstrike/CS_API_CLIENT_SECRET' '/crowdstrike/CLOUDSIM_CID' | python -c"import json, sys; print reduce(lambda m, x: \"\n\".join([m, \"%s=%s\" % (x['Name'].split('/')[-1],x['Value'])]), json.loads(sys.stdin.read())['Parameters'], '')")

curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/download-falcon.py -o /tmp/download-falcon.py

python /tmp/download-falcon.py /tmp/falcon-sensor.rpm

yum -y install /tmp/falcon-sensor.rpm

/opt/CrowdStrike/falcon-ctl -s -f --cid=$CLOUDSIM_CID

systemctl enable falcon-sensor.service
systemctl start falcon-sensor.service

rm /tmp/downlod-falcon.py /tmp/falcon-sensor.rpm
