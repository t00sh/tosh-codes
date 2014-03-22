Title: Authentification avec CERTFP (IRC + irssi)
Date: 2014-02-05
Tags: authentification,irc,irssi
Author: Tosh
Summary: Key based IRC authentification

Sur IRC, nous pouvons enregister notre pseudo grâce au service NickServ, présent maintenant sur quasiment tous les serveurs, afin de s'authentifier et d'empêcher une éventuelle usurpation (Et qui est obligatoire lorsque l'on souhaites avoir des droits supplémentaires sur IRC, comme être opérateur d'un channel).

Or, lors de la phase d'authentification auprès de NickServ (/msg NickServ identify PASSWORD), le password est envoyé en clair sur le réseau, ce qui compromet la sécurité.

CERTFP pour Certificat Fingerprint, est une methode d'authentification utilisant le certificat client du protocole SSL, pour authentifier l'utilisateur sur IRC.

Pour l'utiliser, il faut donc se connecter en SSL, ce qui a en plus l'avantage de chiffrer votre connexion.

Il nous faut dans un premier temps récupérer le certificat du serveur afin de pouvoir le vérifier. Pour Freenode par exemple, il se trouve dans le packet ca-certificates de pas mal de distributions Linux.

Pour HackInt, on peut le trouver sur leur site, signé avec GPG.

Mais bien souvent, ce certificat n'est pas disponible. Nous pouvons le récupérer nous même, en ayant confiance dans le certificat qui nous est présenté à ce moment là. (C'est un risque à prendre)

Par exemple, pour récupérer le(s) certificats d'epiknet, nous pouvons utiliser OpenSSL comme ceci :

	:::console
	$ for serv in `dig +short A irc.epiknet.org`; do echo QUIT | openssl s_client -host $serv -port7002 >> ~/.irssi/certs/epiknet_server.pem; done

Une fois le certificat serveur obtenu, générons notre certificat client, qui permettra de nous authentifier. Ici, avec une clef RSA de 2048 bits, valide pendant 800 jours :

	:::console
	$ umask 077 
	$ cd ~/.irssi/certs
	$ openssl req -nodes -newkey rsa:2048 -days 800 -x509 -keyout hackint_client.key -out hackint_client.cert
	$ cat hackint_client.key hackint_client.cert > hackint_client.pem
	$ rm hackint_client.key hackint_client.cert

NOTE : Ici j'ai utilisé -nodes pour ne pas protéger le certificat avec un password, car j'ai l'impression que celà fait buguer irssi. Mais c'est une bonne chose de le faire.

Configurons maintenant irssi pour qu'il prenne en compte les deux certificats :

    :::console

	{
	  address = "irc.hackint.org";
	  chatnet = "Hackint";
	  port = "9999";
	  use_ssl = "yes";
	  ssl_verify = "yes";
	  ssl_cafile = "/home/USER/.irssi/certs/hackint_server.pem";
	  ssl_cert = "/home/USER/.irssi/certs/hackint_client.pem";
	  autoconnect = "yes";
	}

Connectons nous maintenant à Hackint, et enregistrons-nous en tapant :

	:::console
	/msg nickserv identify PASSWORD

Calculons le fingerprint (sha-1) de notre certificat :

	:::console
	$ openssl x509 -sha1 -noout -fingerprint -in ~/.irssi/certs/hackint_client.pem | sed -e 's/^.*=//;s/://g;y/ABCDEF/abcdef/' 

Retournons sur irssi, et ajoutons le fingerprint permettant de nous authentifier :

	:::console
	/msg Nickserv CERT ADD 00ecf46e2f1cd5aacda14cc98c76ece7114be4104

Voilà, maintenant, nous n'avons plus besoin d'utiliser la commande IDENTIFY de NickServ pour nous authentifier auprès du serveur, ce qui est beaucoup plus sécurisé.

Protégez correctement vos certificats clients : ils permettront d'usurper votre identité si ils sont dérobés.

C'est bien dommage que tous les serveurs IRC ne proposent pas cette methode d'authentification...
