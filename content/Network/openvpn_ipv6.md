Title: Tunnels IPv6, avec OpenVPN
Date: 2014-06-13
Tags: vpn,openvpn,ipv6,tunnel
Author: Tosh
Summary: Utilisation d'IPv6 avec OpenVPN

# Instruduction

Depuis sa version 2.0, OpenVPN supporte le protocole IPv6 or j'ai trouvé assez peu de documentation à ce sujet.

C'est pourquoi j'ai décidé d'écrire un article pour expliquer la marche à suivre afin de mettre en place un tunnel VPN basé sur IPv6.

Lors de ma configuration, le serveur etait hébergé sur un Raspberry-PI basé sur Raspbian, et les clients étaient des ArchLinux.


# Installation

## Installation des paquets nécessaires

Raspbian/Debian :

    :::console
	server# apt-get install openvpn

ArchLinux :

    :::console
	client# pacman -S openvpn

## Génération des clefs et des certificats (serveur)

    :::console
	server# cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/ /etc/openvpn/easy-rsa
	server# cd /etc/openvpn/easy-rsa

Éditer le fichier ./vars, et modifier ces lignes selon votre convenance :

    :::conf
	export KEY_SIZE=2048

    # In how many days should the root CA key expire?
    export CA_EXPIRE=3650

    # In how many days should certificates expire?
    export KEY_EXPIRE=3650

    # These are the default values for fields
    # which will be placed in the certificate.
    # Don't leave any of these fields blank.
    export KEY_COUNTRY="FR"
    export KEY_PROVINCE="Province"
    export KEY_CITY="City"
    export KEY_ORG="Organisation"
    export KEY_EMAIL="user@domain.tld"
    export KEY_CN="Common name"
    export KEY_NAME="Name"
    export KEY_OU="Organisation Unit"

Génération des clefs :

    :::console
	server# source ./vars
	server# ./build-ca
	server# ./build-dh
	server# ./build-key-server server
	server# ./build-key client

Copie les clefs :

    :::console
	server# cp ca.crt ..
	server# cp ca.key ..
	server# cp dh2048.pem ..
	server# cp server.crt ..
	server# cp server.key ..
	server# scp ca.crt @client:/etc/openvpn
    server# scp client.crt @client:/etc/openvpn
	server# scp client.key @client:/etc/openvpn

# Configuration

## Tunnel IPv6

Voici comment configurer un tunnel IPv6, pouvant transporter de l'IPv4 ou de l'IPv6.

![IPv6 tunnel](images/ipv6_tunnel.png)

### Serveur

    :::config
	# Listen port
	port 443

	# Protocol
	proto tcp6-server

	# IP tunnel
	dev tun
	dev tun-ipv6

	# Master certificate
	ca ca.crt

	# Server certificate
	cert neo.crt

	# Server private keu
	key neo.key

	# Diffie-Hellman parameters
	dh dh2048.pem

	# Server mode and subnet
	server 10.8.0.0 255.255.255.0
    server-ipv6 2001:dead::/64

    # Don't need to re-read keys and re-create tun at restart
	persist-key
	persist-tun

	# Ping every 10s. Timeout of 120s.
	keepalive 10 120

	# Enable compression
	comp-lzo

	# User and group
	user nobody
	group nogroup

	# Log a short status
	status openvpn-status.log

	# Logging verbosity
	verb 4

### Client

    :::config
	# Client mode
	client

	# IPv6 tunnel
	dev tun
	tun-ipv6

	# TCP protocol
	proto tcp6-client

	# Address/Port of VPN server
	remote vpn.passerelle.tld 443

	# Don't bind to local port/adress
	nobind

    # Don't need to re-read keys and re-create tun at restart
	persist-key
	persist-tun
	
	# User/Group
	user nobody
	group nobody

	# Master certificate
	ca ca.crt

	# Client certificate
	cert client.crt

	# Client private key
	key  client.key

    # Remote peer must have a signed certificate
    remote-cert-tls server
	ns-cert-type server
    
	# Enable compression
	comp-lzo

## Tunnel IPv4

Voici maintenant comment configurer un tunnel IPv4, pouvant transporter de l'IPv6 ou de l'IPv4.

![IPv4 tunnel](images/ipv4_tunnel.png)

Pour configurer un tunnel ipv4, il suffit juste de changer les lignes dans la configuration client et serveur

    :::config
	proto tcp6-client
	proto tcp6-server

en

    :::config
	proto tcp-client
	proto tcp-server


## Autre réglages

Il y a également d'autres réglages à faire, notamment du côté de la passerelle VPN en ce qui concerne le routage.


Activer l'ip forwarding

    :::config
    server# echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
	server# echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

Masquer les adresses sortantes :

    :::config
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
	ip6tables -t nat -A POSTROUTING -s 2001:dead::/64 -o eth0 -j MASQUERADE

À noter que le MASQUERADE n'est disponble que dans les versions récentes d'iptables et du kernel, et je n'ai pas trouvé de manière plus simple pour mettre en place un réseau privé IPv6 virtuel.

Maintenant, il ne reste plus qu'à ajouter les routes dans les configurations OpenVPN, suivant ce que vous voulez faire passer dans le tunnel.

