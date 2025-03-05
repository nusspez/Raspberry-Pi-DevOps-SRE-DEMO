#!/bin/bash

# Config the Swap on file /etc/dphys-swapfile

# Define swap size of 4GB
SWAP_SIZE_MB=4096

echo "🚀 Change swap and max swap to ${SWAP_SIZE_MB}MB ..."

sudo dphys-swapfile swapoff

sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile

sudo dphys-swapfile setup
sudo dphys-swapfile swapon

free -h

# Install GitLab

sudo apt-get install curl openssh-server ca-certificates apt-transport-https perl

curl https://packages.gitlab.com/gpg.key | sudo tee /etc/apt/trusted.gpg.d/gitlab.asc

sudo apt-get install -y postfix

sudo curl -sS https://packages.gitlab.com/install/repositories/gitlab/raspberry-pi2/script.deb.sh | sudo bash

sudo EXTERNAL_URL="https://gitlab.peznuss.com" apt-get install gitlab-ce
