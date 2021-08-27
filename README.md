Scripts to install the most recent Crowdstrike Falcon agent on Amazon Linux 2, at boot.

```bash
export CS_API_CLIENT_ID="XXXXXXX"
export CS_API_CLIENT_SECRET="YYYYYYYYY"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/asktrim/amazonlinux2-setup-crowdstrike-falcon/main/install.sh)"
```
