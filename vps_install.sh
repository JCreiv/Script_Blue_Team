#!/bin/bash

# Funcion para el color de los mensajes
print_red() {
    echo -e "\033[31m$1\033[0m"
}
print_green() { 
	echo -e "\e[32m$1\e[0m"
}

ctrl_c(){
  print_red -e "\n\n[!] Saliendo...\n"
  exit 1
}

# Ctrl+C
trap ctrl_c INT


# Variables
VPS_USER="root"
SSH_PORT=22  # Cambia esto si usas un puerto diferente
REMOTE_PATH=/root
LOCAL_SCRIPT=./auto.sh


# Pedir al usuario ip del servidor
read -p "IP de tu servidor VPS: " VPS_IP
read -s -p "Contraseña de root: " ROOT_PASS

# Comprobación de que la IP tiene el formato correcto
if [[ ! "$VPS_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    print_red "Error: La IP proporcionada no tiene un formato válido."
    exit 1
fi

# Comprobación de que cada octeto de la IP esté en el rango válido (0-255)
IFS='.' read -r octeto1 octeto2 octeto3 octeto4 <<< "$VPS_IP"
if [[ $octeto1 -gt 255 || $octeto2 -gt 255 || $octeto3 -gt 255 || $octeto4 -gt 255 ]]; then
    print_red "Error: Los octetos de la IP deben estar en el rango de 0 a 255."
    exit 1
fi

# 1. Aceptar automáticamente la clave del VPS
print_green "Añadiendo clave SSH del servidor a known_hosts..."
ssh-keyscan -p $SSH_PORT $VPS_IP >> ~/.ssh/known_hosts 2>/dev/null

# 1. En el host: Generar clave pública si no existe
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    print_green "Generando clave SSH..."
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -C "Javi-Portatil"
fi

# 2. En el VPS: Copiar la clave pública
print_green "Copiando clave pública al VPS..."
sshpass -p "$ROOT_PASS" ssh-copy-id -p $SSH_PORT -i "$HOME/.ssh/id_rsa.pub" "$VPS_USER@$VPS_IP"

sleep 3

# 3. Transferir archivo .sh al VPS
print_green "Transfiriendo $LOCAL_SCRIPT al VPS..."

sshpass -p "$ROOT_PASS" scp -P $SSH_PORT "$LOCAL_SCRIPT" "$VPS_USER@$VPS_IP:$REMOTE_PATH/"

sleep 1 # Esperar un segundo para asegurarse de que el archivo se ha transferido correctamente

sshpass -p "$ROOT_PASS" ssh -p $SSH_PORT "$VPS_USER@$VPS_IP" "bash -s $VPS_IP $ROOT_PASS" <<'EOF'
    SCRIPT=auto.sh
    echo "Ejecutando el script transferido con IP $1 y ROOT_PASS oculto..."
    chmod +x $SCRIPT
    export DEBIAN_FRONTEND=noninteractive
    ./$SCRIPT "$1" "$2"
EOF


#5. En el host: Comandos adicionales
print_green "Configuraciones locales..."
# Aquí puedes agregar comandos que se ejecuten en el host.

print_green "Automatización completada."
