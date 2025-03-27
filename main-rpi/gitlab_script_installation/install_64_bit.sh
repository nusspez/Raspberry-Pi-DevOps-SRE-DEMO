#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

# ========================
# Configuración de Variables
# ========================
# Token personal con scope "api" para la API de GitLab
PRIVATE_TOKEN="MiSuperToken123"
# Nombre y visibilidad del proyecto a crear
PROJECT_NAME="Ansible"
VISIBILITY="private"
# URL de tu instancia GitLab (ajusta si es autohospedada)
GITLAB_URL="http://192.168.100.16"
# En este script se utiliza el token de registro obtenido de la API,
# que se guarda en la variable RUNNER_TOKEN.
# Además, si tu flujo utiliza un token de registro diferente, puedes definirlo aquí:
# REGISTRATION_TOKEN="YourRunnerRegistrationToken"  (no se usa en este ejemplo)

# Configuración del runner
RUNNER_EXECUTOR="shell"       # O "docker" si prefieres usar Docker como ejecutor
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

echo "🧹 Eliminando paquetes obsoletos..."
sudo apt autoremove -y
sudo apt autoclean -y

# ========================
# Configurar Swap a 4GB
# ========================
SWAP_SIZE_MB=4096
echo "🚀 Configurando el Swap a ${SWAP_SIZE_MB}MB..."
sudo dphys-swapfile swapoff
sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SWAP_SIZE_MB/" /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

echo "✅ Estado del Swap:"
free -h

# ========================
# Instalar dependencias necesarias para GitLab
# ========================
echo "🛠️ Instalando dependencias para GitLab..."
sudo apt-get install -y curl openssh-server ca-certificates perl jq

# ========================
# Agregar repositorio e instalar GitLab CE
# ========================
echo "🔑 Configurando el repositorio de GitLab..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

echo "🌍 Configurando los locales..."
sudo bash -c 'echo -e "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\nLC_MESSAGES=en_US.UTF-8" > /etc/default/locale'
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
source /etc/default/locale

echo "🦊 Instalando GitLab CE..."
sudo EXTERNAL_URL="http://$IP" apt-get -y install gitlab-ee
sudo gitlab-ctl reconfigure

echo "⏳ Esperando 30 segundos para que GitLab se inicialice..."
sleep 30

# ========================
# Obtener la contraseña del usuario root y crear token de API
# ========================
ROOT_PASSWORD=$(sudo cat /etc/gitlab/initial_root_password | grep "Password:" | awk '{print $2}')
echo "✅ Contraseña de root obtenida."

# Crear un token de API para root (esto es solo un ejemplo)
ROOT_TOKEN=$(sudo gitlab-rails runner "token = PersonalAccessToken.create!(user: User.find_by(username: 'root'), name: 'RootToken', scopes: ['api'], expires_at: Time.now + 365*24*60*60); token.set_token('MiSuperToken123'); token.save!; puts token.token")
echo "✅ Token de administrador generado: $ROOT_TOKEN"

# ========================
# Crear un nuevo usuario en GitLab
# ========================
SECURE_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
echo "🔑 Contraseña generada para el nuevo usuario: $SECURE_PASSWORD"

EMAIL="nusspez@gmail.com"
USERNAME="peznuss"

echo "👤 Creando el usuario $USERNAME en GitLab..."
USER_RESPONSE=$(curl --silent --request POST "$GITLAB_URL/api/v4/users" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --data "email=$EMAIL&password=$SECURE_PASSWORD&username=$USERNAME&name=$USERNAME&skip_confirmation=true")

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id')
if [ "$USER_ID" == "null" ] || [ -z "$USER_ID" ]; then
  echo "❌ Error: No se pudo crear el usuario."
  exit 1
fi
echo "✅ Usuario $USERNAME creado con ID $USER_ID"

echo "🔧 Otorgando permisos de administrador a $USERNAME..."
curl --request PUT "$GITLAB_URL/api/v4/users/$USER_ID" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --data "admin=true"
echo "✅ $USERNAME ahora es administrador."

echo "✅ Usuario creado con éxito."
echo "🔑 Usuario: $USERNAME"
echo "🔑 Contraseña: $SECURE_PASSWORD"

# ========================
# Crear un proyecto en GitLab y guardar el ID y runner token
# ========================
echo "📦 Creando proyecto en GitLab..."
RESPONSE=$(curl --silent --request POST "$GITLAB_URL/api/v4/projects" \
     --header "PRIVATE-TOKEN: MiSuperToken123" \
     --form "name=$PROJECT_NAME" \
     --form "visibility=$VISIBILITY")

PROJECT_ID=$(echo "$RESPONSE" | jq -r '.id')
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
    echo "❌ Error al crear el proyecto."
    exit 1
fi
echo "✅ Proyecto creado con ID: $PROJECT_ID"

echo "Obteniendo información del proyecto..."
PROJECT_INFO=$(curl --silent --header "PRIVATE-TOKEN: MiSuperToken123" "$GITLAB_URL/api/v4/projects/$PROJECT_ID")
RUNNER_TOKEN=$(echo "$PROJECT_INFO" | jq -r '.runners_token')
echo "✅ Runner token obtenido: $RUNNER_TOKEN"

# ========================
# Instalar GitLab Runner en la Raspberry Pi
# ========================
echo "=== Instalación de GitLab Runner en Raspberry Pi ==="
echo "Descargando GitLab Runner..."
curl -L --output gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm64

chmod +x gitlab-runner
sudo mv gitlab-runner /usr/local/bin/

if ! id -u gitlab-runner >/dev/null 2>&1; then
    echo "Creando el usuario gitlab-runner..."
    sudo useradd --comment "GitLab Runner" --create-home gitlab-runner --shell /bin/bash
fi

echo "Instalando GitLab Runner como servicio..."
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner

echo "Iniciando GitLab Runner..."
sudo gitlab-runner start

echo "Registrando el GitLab Runner..."
sudo gitlab-runner register --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$RUNNER_TOKEN" \
  --executor "shell" \
  --description "Raspberry Pi Runner" \
  --tag-list "rpi,automated" \
  --run-untagged=true \
  --locked=false

echo "✅ GitLab Runner instalado y registrado exitosamente."

# ========================
# agregar llave SSH para agregar codigo de ansible
# ========================

git config --global user.email "nusspez@gmail.com"
git config --global user.name "peznuss"

SSH_KEY="$HOME/.ssh/id_rsa"
ssh-keygen -t rsa -b 4096 -C "nusspez@gmail.com" -f "$SSH_KEY" -N ""
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
ssh-keyscan -H 192.168.100.16 >> ~/.ssh/known_hosts

curl --request POST --header "PRIVATE-TOKEN: MiSuperToken123" \
     --data-urlencode "title=Automated Key" \
     --data-urlencode "key=$SSH_KEY_CONTENT" \
     "$GITLAB_URL/api/v4/user/keys"

# ========================
# agregar el codigo de Ansible automaticamente al nuevo repositorio
# ========================

cd ../ansible
git init --initial-branch=main
git remote add origin git@192.168.100.16:root/Ansible.git
git add .
git commit -m "add ansible project"
git push --set-upstream origin main


TARGET="/home/gitlab-runner/.bash_logout"

sudo tee "$TARGET" > /dev/null << 'EOF'
#if [ "$SHLVL" = 1 ]; then
#    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
#fi
EOF

echo "El archivo $TARGET ha sido actualizado."