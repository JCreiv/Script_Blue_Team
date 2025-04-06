# Seguridad Avanzada en Servidores

Este repositorio contiene un conjunto de scripts diseñados para aumentar la seguridad de un sistema informático. Se dividen en tres partes principales:

## 1. Automatización de Seguridad en Servidores (auto.sh y vps_install.sh)

Los scripts `auto.sh` y `vps_install.sh` automatizan la instalación y configuración de diversas herramientas de seguridad para proteger un servidor. Entre sus funciones principales se incluyen:

- **Habilitar UFW (Uncomplicated Firewall)**: Configuración básica de firewall para restringir accesos no deseados.
- **Securizar la configuración de SSH**:
  - Deshabilitar el acceso root por SSH.
  - Añadir un usuario seguro con permisos restringidos.
  - Configurar autenticación con clave SSH.
  - Cambiar el puerto predeterminado
  - No permitir el login por contraseña
- **Instalar Snort**: Sistema de detección y prevención de intrusiones con reglas personalizadas para monitorizar ataques de ping.
- **Instalar Fail2Ban**: Protección contra ataques de fuerza bruta y escaneo de puertos mediante reglas de bloqueo dinámicas.
- **Instalar Cowrie (Honeypot)**: Servidor SSH falso para detectar y registrar intentos de intrusión.
- **Instalar Knockd**: Sistema de port knocking para ocultar servicios y permitir acceso solo a usuarios autorizados.

### **Comandos útiles de Fail2Ban y Snort**  

#### 🔹 **Fail2Ban**  

- **Verificar estado de los jails activos:**  
  ```bash
  sudo fail2ban-client status
  ```
- **Ver detalles de un jail específico (ejemplo: SSH):**  
  ```bash
  sudo fail2ban-client status sshd
  ```
- **Desbloquear una IP baneada:**  
  ```bash
  sudo fail2ban-client set sshd unbanip <IP>
  ```
- **Banear manualmente una IP en un jail específico:**  
  ```bash
  sudo fail2ban-client set sshd banip <IP>
  ```
- **Ver logs de Fail2Ban en tiempo real:**  
  ```bash
  sudo tail -f /var/log/fail2ban.log
  ```
- **Reiniciar Fail2Ban después de hacer cambios:**  
  ```bash
  sudo systemctl restart fail2ban
  ```
- **Añadir reglas personalizadas en `/etc/fail2ban/jail.local`:**  
  Modifica este archivo para configurar tiempos de baneo, número de intentos, etc.  
  Ejemplo para proteger SSH con un baneo de 10 minutos tras 3 intentos fallidos:
  ```ini
  [sshd]
  enabled = true
  maxretry = 3
  bantime = 600
  findtime = 600
  ```
---

#### 🔹 **Snort**  

- **Ejecutar Snort en modo detección de intrusos:**  
  ```bash
  sudo snort -A console -q -c /etc/snort/snort.conf -i eth0
  ```
- **Analizar tráfico en tiempo real (modo sniffer):**  
  ```bash
  sudo snort -dev -i eth0
  ```
- **Analizar un archivo `.pcap` capturado:**  
  ```bash
  sudo snort -r captura.pcap
  ```
- **Ver registros de alertas generadas:**  
  ```bash
  sudo cat /var/log/snort/snort.alert.fast
  ```

Método de Uso:

```bash
./vps_install.sh
```

---

## 2. Automatización de Port Spoofing (portspoof.sh)

Este script automatiza la técnica de **port spoofing** utilizando [Portspoof](https://github.com/drk1wi/portspoof), una herramienta que:

- Simula puertos abiertos para confundir a posibles atacantes.
- Redirige todas las conexiones a puertos inexistentes hacia un puerto específico.
- Ayuda a proteger la infraestructura ocultando servicios legítimos.

Método de Uso:

```bash
./portspoof.sh
```

---

## 3. Descarga de Logs (script_logs.sh)

Este script permite descargar en cualquier momento distintos tipos de registros del sistema, facilitando la auditoría y el análisis de eventos de seguridad.

Método de Uso:

```bash
./script_logs.sh
```



