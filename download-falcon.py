#!/usr/bin/env python

# Step 1 : Get Sensor Download API credentials
#          create here a sensor download api creds : https://falcon.eu-1.crowdstrike.com/support/api-clients-and-keys
 
# before running the script set the API Creds in env or uncomment and fill below
#export CS_API_CLIENT_ID="XXXXXXX"
#export CS_API_CLIENT_SECRET="YYYYYYYYY"

from __future__ import unicode_literals

try:
    from urllib.parse import urlparse, urlencode
    from urllib.request import urlopen, Request
    from urllib.error import HTTPError
except ImportError:
    from urlparse import urlparse
    from urllib import urlencode
    from urllib2 import urlopen, Request, HTTPError

import os, platform, json, sys, shutil

if sys.version_info[0] >= 3:
    unicode = str

target_cloud_api = os.getenv('CS_API_DOMAIN', 'api.crowdstrike.com')
# Possible values:
# US-1: api.crowdstrike.com
# US-GOV-1: api.laggar.gcw.crowdstrike.com
# EU-1: api.eu-1.crowdstrike.com
# US-2: api.us-2.crowdstrike.com

client_id = os.getenv('CS_API_CLIENT_ID', None)
client_secret = os.getenv('CS_API_CLIENT_SECRET', None)

try:
    destination_filename = sys.argv[1]
except IndexError:
    print("USAGE: download_falcon.py destination_filename")
    exit(1)

if None in [client_id, client_secret]:
    print('Missing CS_API_CLIENT_ID or CS_API_CLIENT_SECRET')
    exit(1)

target_os = os.getenv('CS_FALCON_OS', 'Amazon Linux')
# Possible values:
# "Debian"
# "SLES"
# "RHEL/CentOS/Oracle"
# "Amazon Linux"
# "Debian"
# "Ubuntu"
# "RHEL/CentOS/Oracle"

target_os_version = os.getenv('CS_FALCON_OS_VERSION', '2')

def make_request(req):
    try:
        response = urlopen(req)
        data = response.read()
        response.close()
        return json.loads(data)
    except (HTTPError, ValueError) as exc:
        print("Request failed: %s" % unicode(exc))
        exit(1)

# Authenticate and retrieve a token to use in our API calls
def get_auth_token():
    data = make_request(
        Request(
            "https://%s/oauth2/token" % unicode(target_cloud_api),
            urlencode({
                'client_id': client_id,
                'client_secret': client_secret
            }).encode('ascii')
        )
    )
    return data['access_token']

# Get infos on the latest sensor version
def list_sensor_installers(access_token):
    querystring = urlencode({
        'filter': "platform:\"linux*\"+os:\"%s\"" % target_os,
        'sort': 'version.desc',
        'limit': 5
    })
    data = make_request(
        Request(
            "https://%s/sensors/combined/installers/v1?%s" % (unicode(target_cloud_api), unicode(querystring)),
            None,
            { 'Authorization': "Bearer %s" % access_token }
        )
    )
    return data['resources']

# Download a sensor package through the API
def download_installer(access_token, id, destination_filename):
    querystring = urlencode({ 'id': id })
    req = Request(
        "https://%s/sensors/entities/download-installer/v1?%s" % (unicode(target_cloud_api), unicode(querystring)),
        None,
        { 'Authorization': "Bearer %s" % access_token }
    )
    try:
        response = urlopen(req)
        with open(destination_filename, 'wb') as fp:
            shutil.copyfileobj(response, fp)
        response.close()
    except (HTTPError, ValueError) as exc:
        print("Download failed: %s" % unicode(exc))
        exit(1)

# MAIN
auth_token = get_auth_token()
installers = list_sensor_installers(auth_token)

# we need to check our architecture and download the right sensor version.
# If the arch was not buried in the os version field, we wouldn't need python for this
if platform.machine() in ('arm64', 'aarch64'):
    target_os_version = "%s - arm64" % target_os_version

# our installers are listed newest to oldest, filtered by OS, so grab the first that meet os version target
# The API doesn't support filtering on os version, so we need to parse and iterate over JSON
installer_to_download = None
for installer in installers:
    if installer['os_version'] == target_os_version:
        installer_to_download = installer
        break

if installer_to_download is None:
    print("Could not find an installer")
    exit(1)

print("Downloading installer:")
print(installer_to_download['name'])
print(installer_to_download['description'])
print("to file: %s" % destination_filename)

download_installer(auth_token, installer_to_download['sha256'], destination_filename)

print("Download complete!")
