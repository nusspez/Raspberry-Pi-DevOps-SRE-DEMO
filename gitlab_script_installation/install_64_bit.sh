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
sudo apt-get install -y curl openssh-server ca-certificates perl jq

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

echo "⏳ Esperando 30 segundos para que GitLab se inicialice..."
sleep 30

# 🚀 Obtener la contraseña del usuario root
ROOT_PASSWORD=$(sudo cat /etc/gitlab/initial_root_password | grep "Password:" | awk '{print $2}')
echo "✅ Contraseña de root obtenida."

# 🚀 Crear un token de administrador para la API
ROOT_TOKEN=$(sudo gitlab-rails runner "token = PersonalAccessToken.create!(user: User.find_by(username: 'root'), name: 'RootToken', scopes: ['api'], expires_at: Time.now + 365*24*60*60); token.set_token('MiSuperToken123'); token.save!; puts token.token")
echo "✅ Token de administrador generado."

# 🚀 Generar una contraseña segura sin caracteres especiales
SECURE_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
echo "🔑 Contraseña generada para el nuevo usuario."

# 🚀 Datos del nuevo usuario
EMAIL="nusspez@gmail.com"
USERNAME="peznuss"

# 🚀 Crear un nuevo usuario en GitLab
echo "👤 Creando el usuario $USERNAME en GitLab..."
USER_ID=$(curl --silent --request POST "http://$IP/api/v4/users" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --data "email=$EMAIL&password=$SECURE_PASSWORD&username=$USERNAME&name=$USERNAME&skip_confirmation=true" | jq -r '.id')

if [ "$USER_ID" == "null" ] || [ -z "$USER_ID" ]; then
  echo "❌ Error: No se pudo crear el usuario."
  exit 1
fi

echo "✅ Usuario $USERNAME creado con ID $USER_ID"

# 🚀 Convertir el usuario en administrador
echo "🔧 Otorgando permisos de administrador a $USERNAME..."
curl --request PUT "http://$IP/api/v4/users/$USER_ID" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --data "admin=true"

echo "✅ $USERNAME ahora es administrador."

echo "✅ Usuario creado con éxito."
echo "🔑 Usuario: $USERNAME"
echo "🔑 Contraseña: $SECURE_PASSWORD"

#crear un proyecto de Gitlab 

curl --request POST "https://gitlab.com/api/v4/projects" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --form "name=Ansible" \
     --form "visibility=private"


