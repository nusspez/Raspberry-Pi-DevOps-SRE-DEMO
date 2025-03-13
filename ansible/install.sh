#!/bin/bash
set -e  # Sale si algún comando falla

echo "Actualizando paquetes..."
sudo apt update -y && sudo apt upgrade -y

echo "Instalando Python3 y pip3..."
sudo apt install -y python3 python3-pip

echo "Instalando Ansible mediante pip3..."
pip3 install --user ansible

# Asegúrate de que el directorio de binarios de pip esté en tu PATH
export PATH="$HOME/.local/bin:$PATH"

echo "Verificando la instalación de Ansible..."
ansible --version

echo "Instalación de Ansible completada."