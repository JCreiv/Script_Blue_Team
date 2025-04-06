#!/bin/bash

# Configuración
read -p "Ingrese la IP del VPS: " REMOTE_HOST
read -p "Ingrese el usuario del VPS: " REMOTE_USER
read -s -p "Ingrese la contraseña del VPS: " REMOTE_PASS
echo

# Validación de IP con formato correcto (4 octetos numéricos)
if [[ ! $REMOTE_HOST =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Error: IP no válida. Inténtelo de nuevo."
    exit 1
fi

# Comprobación de que cada octeto esté en el rango 0-255
IFS='.' read -r octeto1 octeto2 octeto3 octeto4 <<< "$REMOTE_HOST"
for octeto in "$octeto1" "$octeto2" "$octeto3" "$octeto4"; do
    if [[ -z $octeto || $octeto -lt 0 || $octeto -gt 255 ]]; then
        echo "Error: Los octetos de la IP deben estar en el rango de 0 a 255."
        exit 1
    fi
done

REMOTE_LOG_PATH="/var/log/"
LOCAL_BACKUP_DIR="./backup_logs"

# Menú de selección de logs
echo "Seleccione una opción:"
echo "1) Descargar logs más importantes del sistema"
echo "2) Especificar manualmente la ruta de un log"
read -p "Opción: " OPTION

case $OPTION in
    1)
        # Logs más importantes del sistema
        LOG_FILES=("syslog" "auth.log" "secure" "dmesg" "boot.log" "cron")
        ;;
    2)
        # Especificar ruta de archivo
        read -p "Ingrese la ruta completa del archivo de log: " CUSTOM_LOG
        LOG_FILES=($(basename "$CUSTOM_LOG"))
        REMOTE_LOG_PATH=$(dirname "$CUSTOM_LOG")/
        ;;
    *)
        # Opción no válida
        echo "Opción no válida. Saliendo..."
        exit 1
        ;;
esac

# Crear directorio local con marca de tiempo (solo día y hora)
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M")
BACKUP_PATH="$LOCAL_BACKUP_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

# Descargar logs y mostrar los errores detallados
for FILE in "${LOG_FILES[@]}"; do
    sshpass -p "$REMOTE_PASS" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_LOG_PATH$FILE" "$BACKUP_PATH/" 
    if [ $? -ne 0 ]; then
        echo "Error descargando: $FILE. Verifique si tiene los permisos adecuados o si el archivo existe en la ruta."
    else
        echo "Descargado: $FILE"
    fi
done

# Confirmación
echo "Backup completado en $BACKUP_PATH"