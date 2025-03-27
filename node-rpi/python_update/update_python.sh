#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

sudo apt update
sudo apt upgrade -y
python3 --version