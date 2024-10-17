# Herramienta-WIFI-fake
Con esta herramienta podras crear tu punto de acceso de manera automatizada, cuando un usuario intente autenticarse lo mandara a un panel de autenticacion de facebook u otras plantillas que cuentan con la herramienta

Debera agregar estas lineas al archivo /etc/dnsmasq.conf

interface=wlan0mon #Cambia por el nombre de tu interfaz de monitor

dhcp-range=10.0.0.2,10.0.0.20,255.255.255.0,24h

address=/#/10.0.0.1 #Todas las peticiones DNS serán resueltas a tu IP

Tambien tendra que tener instalado Apache2, dnsmasq, PHP, tambien se utilzaran herramientas como airbase o aircrack pero estas ya estan instaladas en sistemas operativos Kali linux y Parrot OS que es donde se recomienda ejecutar el script

Al igual que debera tener una antena de red conectada a su maquina para que funcione de manera correcta

Este script fue hecho con intenciones de aprendizaje no deberia utilzarse para actividades ilagales o no eticas
