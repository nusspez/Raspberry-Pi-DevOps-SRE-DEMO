#!/bin/bash
set -e  # Detiene el script en caso de error
export DEBIAN_FRONTEND=noninteractive

# ========================
# Configuración de Variables
# ========================
PRIVATE_TOKEN="${GITLAB_PRIVATE_TOKEN:-MiSuperToken123}"
PROJECT_NAME="Ansible"
VISIBILITY="private"
GITLAB_URL="http://192.168.100.16"
RUNNER_EXECUTOR="shell"
RUNNER_DESCRIPTION="Raspberry Pi Runner"

# ========================
# Obtener la IP de la Raspberry Pi
# ========================
IP=$(hostname -I | awk '{print $1}')

# ========================
# Actualizar el sistema y limpiar
# ========================
echo "🔄 Actualizando dependencias..."
sudo apt update -y && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

# ========================
# Configurar Swap a 4GB
# ========================
SWAP_SIZE_MB=4096
echo "🚀 Configurando Swap a ${SWAP_SIZE_MB}MB..."
sudo dphys-swapfile swapoff
sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
free -h

# ========================
# Instalar dependencias necesarias
# ========================
echo "🛠️ Instalando dependencias..."
sudo apt-get install -y curl openssh-server ca-certificates perl jq

# ========================
# Configurar e instalar GitLab
# ========================
echo "🦊 Instalando GitLab..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://$IP" apt-get -y install gitlab-ee
sudo gitlab-ctl reconfigure
sleep 30  # Esperar a que GitLab termine de iniciarse

# ========================
# Crear un nuevo usuario en GitLab
# ========================
EMAIL="nusspez@gmail.com"
USERNAME="peznuss"
SECURE_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

echo "👤 Creando usuario en GitLab..."
USER_RESPONSE=$(curl --silent --request POST "$GITLAB_URL/api/v4/users" \
     --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
     --data "email=$EMAIL&password=$SECURE_PASSWORD&username=$USERNAME&name=$USERNAME&skip_confirmation=true")

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id')
if [ -z "$USER_ID" ] || [ "$USER_ID" == "null" ]; then
  echo "❌ Error: No se pudo crear el usuario."
  exit 1
fi
echo "✅ Usuario creado con ID $USER_ID"

# ========================
# Crear proyecto en GitLab
# ========================
echo "📦 Creando proyecto en GitLab..."
RESPONSE=$(curl --silent --request POST "$GITLAB_URL/api/v4/projects" \
     --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
     --form "name=$PROJECT_NAME" \
     --form "visibility=$VISIBILITY")

if echo "$RESPONSE" | jq -e '.id' >/dev/null; then
    PROJECT_ID=$(echo "$RESPONSE" | jq -r '.id')
    echo "✅ Proyecto creado con ID: $PROJECT_ID"
else
    echo "❌ Error al crear el proyecto. Respuesta de GitLab: $RESPONSE"
    exit 1
fi

# ========================
# Instalar GitLab Runner
# ========================
echo "=== Instalación de GitLab Runner ==="
curl -L --output gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm64
chmod +x gitlab-runner
sudo mv gitlab-runner /usr/local/bin/

if ! id -u gitlab-runner >/dev/null 2>&1; then
    sudo useradd --comment "GitLab Runner" --create-home gitlab-runner --shell /bin/bash
fi

sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start

# ========================
# Generar clave SSH si no existe
# ========================
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
    echo "🔑 Generando clave SSH..."
    ssh-keygen -t rsa -b 4096 -C "nusspez@gmail.com" -f "$SSH_KEY" -N ""
fi

eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")

curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
     --data-urlencode "title=Automated Key" \
     --data-urlencode "key=$SSH_KEY_CONTENT" \
     "$GITLAB_URL/api/v4/user/keys"

# ========================
# Agregar código de Ansible al repositorio GitLab
# ========================
cd ../ansible

# Verificar si Git ya está inicializado
if [ ! -d ".git" ]; then
    echo "⚡ Inicializando Git en el directorio de Ansible..."
    git init --initial-branch=main
fi

# Evitar duplicados en el remote
if ! git remote | grep -q "origin"; then
    git remote add origin git@192.168.100.16:root/Ansible.git
fi

git add .
git commit -m "Add Ansible project"
git push --set-upstream origin main || echo "⚠️ Error al hacer push. Verifica SSH."

echo "🚀 Todo listo: GitLab, GitLab Runner y Ansible configurados."