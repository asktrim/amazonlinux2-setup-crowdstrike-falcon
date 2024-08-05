#! /bin/bash

set -e
set -v

sudo yum install -y yum-cron binutils yum-plugin-kernel-livepatch kpatch-runtime libnl

# Overwrite yum-cron.conf sections
sudo sed -i "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
sudo sed -i "s/update_cmd = default/update_cmd = security/" /etc/yum/yum-cron.conf

# enable and start yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Install and enable live kernel pathcing
sudo yum kernel-livepatch enable -y
sudo amazon-linux-extras enable livepatch

if command -v aws &> /dev/null
then
  export $(aws ssm get-parameters --region "us-east-1" --with-decryption --names '/crowdstrike/CS_API_CLIENT_ID' '/crowdstrike/CS_API_CLIENT_SECRET' '/crowdstrike/CLOUDSIM_CID' '/crowdstrike/CLOUDSIM_TAGS' '/salt/SALT_BACKEND_HOST' '/salt/SALT_TOKEN' '/trim/TRIM_INSTANCE_PKG_BUCKET' | python -c"import json, sys; print reduce(lambda m, x: \"\n\".join([m, \"%s=%s\" % (x['Name'].split('/')[-1],x['Value'])]), json.loads(sys.stdin.read())['Parameters'], '')")

  # Download falcon download script
  curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/download-falcon.py -o /tmp/download-falcon.py

  # run download script
  python /tmp/download-falcon.py /tmp/falcon-sensor.rpm

  # install and configure falcon
  sudo yum -y install /tmp/falcon-sensor.rpm

  sudo /opt/CrowdStrike/falconctl -s -f --cid=$CLOUDSIM_CID --tags=$CLOUDSIM_TAGS --trace=debug --feature=enableLog

  # enable and start falcon
  sudo systemctl enable falcon-sensor.service
  sudo systemctl start falcon-sensor.service

  #Install salt sensor
  sudo amazon-linux-extras install -y epel
  sudo amazon-linux-extras enable python3.8 
  sudo yum install -y python3.8

  #Download rpm file  
  aws s3 cp s3://$TRIM_INSTANCE_PKG_BUCKET/salt-linux-sensor-9.3.7.x86_64.rpm . 
  #Configure the sensor:
  sudo yum -y install salt-linux-sensor-9.3.7.x86_64.rpm
  sudo salt-sensor configure --skip-dialog --backend_host $SALT_BACKEND_HOST --token $SALT_TOKEN --promiscuous_mode true --ingress_mode true --http_mode true
  #After installation you may perform Pre-Flight checks:
  #sudo salt-sensor pre-flight-checks
  #Start salt sensor:
  sudo salt-sensor start
  #Check sensor status:
  #sudo salt-sensor status
fi
