#!/bin/bash

# You need to go log in to http://${bldr_fqdn} as admin and generate a core origin.
# You will also need to generate a Personal Access Token for use in this script.

export HAB_AUTH_TOKEN="INSERT_TOKEN_HERE"
cd /opt/on-prem-builder
sudo -E ./scripts/on-prem-archive.sh populate-depot http://${bldr_fqdn}/
