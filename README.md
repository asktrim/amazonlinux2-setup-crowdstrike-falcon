Scripts to install the most recent Crowdstrike Falcon agent on Amazon Linux 2, at boot.

Make sure your EC2 instances can access and decrypt SSM Parameters. Set the following Parameters:
- `/crowdstrike/CS_API_CLIENT_ID`
- `/crowdstrike/CS_API_CLIENT_SECRET`
- `/crowdstrike/CLOUDSIM_CID`

Run this command as part of your instance startup, or at any other time.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/install.sh)"
```
