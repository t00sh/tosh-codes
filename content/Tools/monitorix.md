Title: Monitorix - Ou comment monitorer facilement votre serveur !
Date: 2014-08-29
Tags: monitoring,network,linux
Author: Tosh
Summary: A tool for monitoring your server

Salut salut !
J'ai décidé d'écrire un petit article sur un outil de monitoring assez peu connu : **[Monitorix](http://www.monitorix.org/)**.

Et vu que la version **3.6.0** vient de sortir le **20 août 2014**, ça tombe plutôt bien !

Pour faire simple, **[Monitorix](http://www.monitorix.org/)** est un logiciel libre publié sous licence **GPLv2**.
Celui-ci permet de monitorer un serveur grâce à un ensemble de graphiques, donnant ainsi une vue d'ensemble des ressources utilisées par la machine.

Les graphiques peuvent être visualisés grâce à une interface web, ce qui en facilite son utilisation.
Ces derniers sont assez nombreux, et peuvent être selectionnés depuis le fichier de configuration. Parmis eux, on retrouve :

- Le system load
- La taille des partitions
- La bande passante utilisée
- Le nombre de connexions IPv6/IPv4
- Le nombre de processus
- Le traffic réseau par port
- Les utilisateurs loggués
- Les requêtes HTTP

Les principaux avantages de [Monitorix](http://www.monitorix.org/), sont :

- Une installation facile à mettre en place : pas besoin d'installer une base de donnée ou un serveur web ; depuis sa version 3.0, [Monitorix](http://www.monitorix.org/) intègre un serveur HTTP.
- Une configuration simplifié : tout se fait depuis un unique fichier texte.
- Un outil documenté : le site et les pages de manuel sont clairs et à jour.
- Tourne sur de nombreux UNIX et Linux.
- Consomme peu de ressources.

Voici quelques screens pour vous mettre l'eau à la bouche :

![screen 1](images/monitorix_1.jpg)
![screen 2](images/monitorix_2.jpg)
![screen 3](images/monitorix_3.jpg)
![screen 4](images/monitorix_4.jpg)

Je ne fais pas de tuto concernant l'installation et la configuration, il y a déjà tout ce qu'il faut sur le site de **[Monitorix](http://www.monitorix.org/)** : [http://www.monitorix.org/](http://www.monitorix.org/).