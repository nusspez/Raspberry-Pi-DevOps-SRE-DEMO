#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

# 🚀 Actualizar dependencias sin preguntar
echo "🔄 Actualizando dependencias..."
yes | sudo apt update -y && sudo apt upgrade -y

# 🚀 Limpiar paquetes innecesarios sin confirmación
echo "🧹 Eliminando paquetes obsoletos..."
yes | sudo apt autoremove -y
yes | sudo apt autoclean -y

# 🚀 Configurar Swap a 4GB
SWAP_SIZE_MB=4096
echo "🚀 Configurando el Swap a ${SWAP_SIZE_MB}MB..."

sudo dphys-swapfile swapoff
sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile
yes | sudo dphys-swapfile setup
yes | sudo dphys-swapfile swapon

# 🚀 Verificar el Swap
echo "✅ Estado del Swap:"
free -h

# 🚀 Instalar dependencias de GitLab sin pedir confirmación
echo "🛠️ Instalando dependencias para GitLab..."
yes | sudo apt-get install -y curl openssh-server ca-certificates apt-transport-https perl

# 🚀 Agregar clave GPG y repositorio de GitLab
echo "🔑 Configurando el repositorio de GitLab..."
yes | curl -fsSL https://packages.gitlab.com/gpg.key | sudo tee /etc/apt/trusted.gpg.d/gitlab.asc
yes | sudo curl -sS https://packages.gitlab.com/install/repositories/gitlab/raspberry-pi2/script.deb.sh | sudo bash

# 🚀 Instalar GitLab CE sin interacción
echo "🦊 Instalando GitLab CE..."
yes | sudo apt-get install -y gitlab-ce

echo "✅ Instalación completa. Ejecuta 'sudo gitlab-ctl reconfigure' para finalizar la configuración."