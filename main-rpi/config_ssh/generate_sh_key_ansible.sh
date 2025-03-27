#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible

hosts=("192.168.1.101" "192.168.1.102" "192.168.1.103")

# Define el usuario remoto que se utilizará para la conexión SSH
usuario="peznuss"

# Itera sobre cada host en la lista
for host in "${hosts[@]}"; do
    echo "Copiando la llave SSH a $usuario@$host..."
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$usuario@$host"
done

echo "Llave SSH copiada a todos los hosts."