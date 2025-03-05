#!/bin/bash

#config the Swap on file /etc/dphys-swapfile

# define swap size of 4GB
SWAP_SIZE_MB=4096
CONF_MAXSWAP=4096

echo "🚀 Change swap and max swap to ${SWAP_SIZE_MB}MB ..."

sudo dphys-swapfile swapoff

sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile

sudo dphys-swapfile setup
sudo dphys-swapfile swapon

free -h