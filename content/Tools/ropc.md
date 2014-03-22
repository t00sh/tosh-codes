Title: RopC 1.0
Date: 2012-11-28
Tags: tools,rop
Author: Tosh
Summary: Generate Gadgets for return oriented programming

Voici un petit article pour présenter un petit outil de ma conception, permettant d'automatiser les étapes nécessaire au Return Oriented Programming.

Vu que l'outil est fonctionnel, je lui ai donné le numéro de version 1.0.
Pourquoi s'appelle t'il ROPC ?

ROP pour l'abréviation de Return Oriented Programming, et C simplement parce qu'il est écrit en langage C. Original, hein ?
Qu'est-ce que le ROP ?

Le ROP est un ensemble de techniques utilisées dans l'exploitation de vulnérabilité de type buffer overflow, format string et compagnie, permettant généralement de contourner les protections modernes telles que l'ASLR, NX bit, etc. (Je ferais peut être un article prochainement sur ces différentes protections).
ROPC fonctionne sur quelles plateformes ?

Pour le moment, il ne fonctionne que sur Linux avec le format ELF 32 bits.
Utilisation :

	:::console
	Usage : ropc [options]
	Options : 
	  -s <string>    Search string in memory.
	  -g             Search gadgets.
	  -f <file>      Search on file.
	  -d <depth>     Depth for gadgets searching.
	  -b <bad>       Bad chars on address.
	  -0             Genere stage0.
	  -F             Filter gadgets.
	  -N             No colors.
	  -h             Print help.
	  -v             Print current version.

Rechercher tous les gadgets

	:::console
	$ ropc -f a.out -g
	Searching on segment 2 (+X)...
	0x0804865f -> or [edi],al ; sbb eax,0x83530000 ; in al,dx ; or al,ch ; ret ; 
	0x08048660 -> pop es ; sbb eax,0x83530000 ; in al,dx ; or al,ch ; ret ; 
	0x08048661 -> sbb eax,0x83530000 ; in al,dx ; or al,ch ; ret ; 
	0x08048663 -> add [ebx-0x7d],dl ; in al,dx ; or al,ch ; ret ; 
	0x08048666 -> in al,dx ; or al,ch ; ret ;
	...
	1421 gadgets found.

Rechercher des gadgets, en appliquant les filtres du programme

	:::console
	$ ropc -f a.out -g -F
	Searching on segment 2 (+X)...
	0x08048669 -> ret ; 
	0x0804866e -> ret ; 
	0x08048682 -> add esp,0x8 ; pop ebx ; ret ; 
	0x08048685 -> pop ebx ; ret ; 
	0x08048686 -> ret ;
	...
	271 gadgets found.

Rechercher des gadgets en appliquant un filtre, et en spécifiant des mauvais caractères pour l'addresse

	:::console
	$ ropc -f a.out -g -F -b "\x00\x6e"
	Searching on segment 2 (+X)...
	0x08048669 -> ret ; 
	0x08048682 -> add esp,0x8 ; pop ebx ; ret ; 
	0x08048685 -> pop ebx ; ret ; 
	0x08048686 -> ret ; 
	0x08048904 -> ret ;
	...
	266 gadgets found.

Rechercher une chaine de caractère dans le fichier en spécifiant les mauvais caractères pour l'addresse

	:::console
	$ ropc -f a.out -s "/bin/sh\x00" -b "\x0a"
	0x08048138 -> \x2f
	0x0804dc79 -> \x62\x69\x6e
	0x08048138 -> \x2f
	0x0804d86f -> \x73\x68\x00
	4 strings found

Générer le stage0 (actuellement, seulement la methode par strcpy et la sortie en Perl est géré) :

	:::console
	$ ropc -f a.out -s "\x6e\x89\xe7\x52\x57\x55\x51\x50\x53\x89\xe1\x31\xc0\xb0\x0b\xcd\x80" -0
	# \x6e
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', 0x0804f000);
	$payload .= pack('L', 0x0804813e);

	# \x89
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', 0x0804f001);
	$payload .= pack('L', 0x0804887b);
	...

 

Voilà un petit aperçu de l'outil. J'ai encore pleins d'idées à implémenter, telles que :

* Meilleur gestion des couleurs dans le terminal.
* Autres techniques de stage0 (autres fonctions, utilisation de gadgets, etc)
* Implémentation de quelques techniques pour générer un stage1 : ret2libc, shellcode...
* Support pour l'ELF 64
* Ajout de la syntaxe AT&T
* Revoir un peu le fonctionnement des filters.

Vous pouvez suivre l'avancement et tester mon outil sur github :

[github](https://github.com/t00sh/ropc)

Si vous avez des bugs à soumettre, un patch à proposer ou des suggestions à faire, vous pouvez me contacter à l'addresse : randt0sh [at] gmail [dot] com
