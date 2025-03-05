import subprocess
import os

def run_command(cmd):
    print(f"🔹 Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

# 🚀 Obtener el nombre de la distribución
distro_codename = subprocess.check_output("lsb_release -cs", shell=True, text=True).strip()

# 🚀 Actualizar el sistema
run_command("sudo apt update -y && sudo apt upgrade -y")

# 🚀 Instalar dependencias necesarias
run_command("sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release")

# 🚀 Agregar la clave GPG de Docker
run_command("curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg")

# 🚀 Agregar el repositorio de Docker con el código de la versión correcta
run_command(f"echo 'deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian {distro_codename} stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null")

# 🚀 Actualizar paquetes de nuevo para incluir Docker
run_command("sudo apt update -y")

# 🚀 Instalar Docker
run_command("sudo apt install -y docker-ce docker-ce-cli containerd.io")

# 🚀 Habilitar y arrancar Docker
run_command("sudo systemctl enable docker")
run_command("sudo systemctl start docker")

# 🚀 Agregar el usuario actual al grupo Docker para evitar usar `sudo`
current_user = os.getenv("SUDO_USER") or os.getenv("USER")
run_command(f"sudo usermod -aG docker {current_user}")

print("🔄 Cambios aplicados. Es necesario cerrar sesión o reiniciar la Raspberry Pi para aplicar los cambios.")

# ✅ Verificar si Docker está instalado correctamente
print("🔍 Verificando la instalación de Docker...")
subprocess.run("docker --version", shell=True, check=True)

print("✅ Docker instalado correctamente. 🚀")