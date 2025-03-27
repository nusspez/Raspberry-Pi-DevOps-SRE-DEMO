import subprocess
import os

def run_command(cmd):
    print(f"🔹 Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

# 🚀 Obtener el nombre de la distribución (aunque en este caso no lo usamos directamente)
distro_codename = subprocess.check_output("lsb_release -cs", shell=True, text=True).strip()
print(f"📌 Distribución detectada: {distro_codename}")

# 🚀 Actualizar el sistema
run_command("sudo apt update -y && sudo apt upgrade -y")

# 🚀 Instalar dependencias necesarias
run_command("sudo curl -sL https://raw.githubusercontent.com/ezekeal/scripts/main/docker-pi.sh | bash")

# 🚀 Agregar la clave GPG de Docker
run_command("sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc")

# 🚀 Asegurarse de que la clave tenga permisos de lectura
run_command("sudo chmod a+r /etc/apt/keyrings/docker.asc")

# 🚀 Agregar el repositorio de Docker
# Usamos una cadena con comillas simples para el Python, y escapamos las comillas internas necesarias.
run_command('echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null')

# 🚀 Actualizar paquetes para incluir Docker
run_command("sudo apt update -y")

# 🚀 Instalar Docker y componentes adicionales
run_command("sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin")

# 🚀 Agregar el usuario actual al grupo Docker (para evitar usar sudo)
current_user = os.getenv("SUDO_USER") or os.getenv("USER")
run_command(f"sudo usermod -aG docker {current_user}")

run_command("sudo apt install -y docker-compose")

print("🔄 Cambios aplicados. Es necesario cerrar sesión o reiniciar la Raspberry Pi para aplicar los cambios.")

# ✅ Verificar si Docker está instalado correctamente
print("🔍 Verificando la instalación de Docker...")
subprocess.run("docker --version", shell=True, check=True)

subprocess.run("docker-compose --version", shell=True, check=True)



print("✅ Docker instalado correctamente. 🚀")