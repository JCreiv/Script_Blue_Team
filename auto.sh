#!/bin/bash
#export TERM=xterm-256color
#source /etc/skel/.bashrc

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

# IP servidor Wazuh
VPS_IP=$1
ROOT_PASS=$2

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


apt update -y
#apt upgrade -y
#apt install timeshift -y
#timeshift --create --comments "Initial Setup"

ufw allow 22/tcp
ufw allow 1515/tcp
ufw allow 1514/tcp
echo "y" | ufw enable
ufw reload

ufw allow 2424/tcp
ufw reload

sed -i 's/#\?Port [0-9]*/Port 2424/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

systemctl enable ssh.service
systemctl restart ssh.service

apt install snort -y

# Configurar la red para monitorizar
sudo sed -i "s|^DEBIAN_SNORT_HOME_NET=\".*\"|DEBIAN_SNORT_HOME_NET=\"$VPS_IP/32\"|" /etc/snort/snort.debian.conf

apt install fail2ban -y

apt-get install git python3-venv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind -y

iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

ufw allow 2222/tcp
ufw reload

adduser --disabled-password --gecos "" cowrie

su - cowrie -c "
cd /home/cowrie
git clone http://github.com/cowrie/cowrie
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
bin/cowrie start
"


#systemctl daemon-reload 
#systemctl enable wazuh-agent.service
#systemctl start wazuh-agent.service 

# Añadir el usuario javi sin contraseña
USER_NAME=javi
adduser --disabled-password --shell /bin/bash --gecos "" $USER_NAME

# Verificar variable ROOT_PASS
if [ -z "$ROOT_PASS" ]; then
  echo "ERROR: La variable ROOT_PASS no está definida. Abortando."
  exit 1
fi

# Asignar contraseña
echo "$USER_NAME:$ROOT_PASS" | sudo chpasswd

# Mensaje de confirmación
print_green "Usuario '$USER_NAME' creado con shell '/bin/bash' y contraseña asignada."

# Añadir al grupo sudo
usermod -aG sudo $USER_NAME

print_green "Usuario '$USER_NAME' añadido al grupo 'sudo'."

# Copiar clave SSH y ajustar permisos
cp -r /root/.ssh /home/$USER_NAME
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh
chmod 700 /home/$USER_NAME/.ssh
chmod 600 /home/$USER_NAME/.ssh/authorized_keys

# Deshabilitar login root por SSH
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh.service
print_green "Login root por SSH deshabilitado."


# Añadir regla de alerta ICMP a Snort
echo 'alert icmp 92.119.141.208 any -> any any (msg:"ALERTA PINGAZO: Posible intrusión desde la IP de la escuela"; sid:1000001; rev:1;)' >> /etc/snort/rules/local.rules
sudo systemctl restart snort
print_green "Regla de alerta ICMP añadida a Snort."

# Instalar Knockd
apt install knockd

# Configurar Knockd cambiar puertos y habilitar tarjeta de red
sed -i -e 's/9000/2424/g' -e 's/8000/4444/g' -e 's/7000/7777/g' /etc/knockd.conf
sed -i -e 's/START_KNOCKD=0/START_KNOCKD=1/' -e 's/#KNOCKD_OPTS="-i eth1"/KNOCKD_OPTS="-i eth0"/' /etc/default/knockd
sed -i 's/dport 22/dport 2424/g' /etc/knockd.conf
systemctl start knockd
systemctl enable knockd
systemctl status knockd

print_green "Knockd configurado y habilitado. puertos para abrir: 2424, 4444, 7777 puertos para cerrar: 7777, 4444, 2424"

print_green "Configuración finalizada. Por favor inicia al servidor por ssh por el puerto 2424 con el usuario javi."
