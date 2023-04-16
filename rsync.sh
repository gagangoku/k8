#!/bin/bash

set -x
set -e

# Linode
#rsync -r -avzh --exclude '.streamlit' --exclude '.idea' --exclude 'build' --exclude 'dist' --exclude 'venv' --exclude '.git' ./ gagan@api.liquidco.in:~/noti-insights/

# Gcp
rsync -Pa -e "ssh -t -i /Users/gagandeepsingh/.ssh/google_compute_engine -o CheckHostIP=no -o HashKnownHosts=no -o HostKeyAlias=compute.8593189175368638566 -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/Users/gagandeepsingh/.ssh/google_compute_known_hosts" --exclude supergroup.out --exclude venv --exclude .streamlit --exclude .git --exclude mdtest.db --exclude mdtest/mdtest ./ gagandeep@gcp.liquidco.in:~/k8/
