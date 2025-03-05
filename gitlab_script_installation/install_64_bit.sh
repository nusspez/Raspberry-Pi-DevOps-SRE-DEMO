#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

# 🚀 Obtener la IP automáticamente
IP=$(hostname -I | awk '{print $1}')

# 🚀 Actualizar dependencias sin preguntar
echo "🔄 Actualizando dependencias..."
sudo apt update -y && sudo apt upgrade -y

# 🚀 Limpiar paquetes innecesarios sin confirmación
echo "🧹 Eliminando paquetes obsoletos..."
sudo apt autoremove -y
sudo apt autoclean -y

# 🚀 Configurar Swap a 4GB
SWAP_SIZE_MB=4096
echo "🚀 Configurando el Swap a ${SWAP_SIZE_MB}MB..."

sudo dphys-swapfile swapoff
sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# 🚀 Verificar el Swap
echo "✅ Estado del Swap:"
free -h

# 🚀 Instalar dependencias de GitLab sin pedir confirmación
echo "🛠️ Instalando dependencias para GitLab..."
sudo apt-get install -y curl openssh-server ca-certificates perl

# 🚀 Agregar clave GPG y repositorio de GitLab
echo "🔑 Configurando el repositorio de GitLab..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

# 🚀 Configurar Locales
echo "🌍 Configurando los locales..."
sudo bash -c 'echo -e "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\nLC_MESSAGES=en_US.UTF-8" > /etc/default/locale'
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
source /etc/default/locale

# 🚀 Instalar GitLab CE sin interacción
echo "🦊 Instalando GitLab CE..."
sudo EXTERNAL_URL="http://$IP" apt-get -y install gitlab-ee
sudo gitlab-ctl reconfigure

echo "✅ Instalación completa."

cat /etc/gitlab/initial_root_password

echo # WARNING: This file will be automatically deleted in 24 hours.