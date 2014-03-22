Title: Protections modernes contre l'exploitations de failles applicatives (Linux)
Date: 2013-08-25
Tags: overflow,protection
Author: Tosh
Summary: Brieve list and explanations about modern protections against app vulnerabilities (Linux case)

De retour sur mon blog !

Voici un petit article pour vous donner un petit aperçu des protections présentes sur un système Linux moderne pour contrer les attaques applicatives.

Il est question de x86 ici.

## SSP

SSP, pour Stack Smashing Protection, est une protection introduite par GCC depuis sa version 4.1.

Cette protection permet de grandement limiter les débordements sur la pile de plusieurs manières :

- En plaçant un "Cookie" (Généralement une valeur aléatoire ou semi-aléatoire) entre les variables locales et le saved-ebp et le saved-eip des fonctions à risques.

- En recopiant les arguments des fonctions sur la pile.

- En réorganisant les variables locales des fonctions.

 

Pour illustrer la manière dont est mise en oeuvre SSP, prenons un exemple :

    :::c
    #include <string.h>
	#include <stdio.h>

	void foo(char *arg) {
    	int i = 42;

    	char buff[20];
    	strcpy(buff, arg);
    	printf("%d\n", i);
	}

	int main(int argc, char **argv) {

    	if(argc > 1)
        	foo(argv[1]);

    	return 0;
	}

Compilons sans activer SSP (option -fno-stack-protector) et désassemblons la fonction foo :

	:::objdump
	08048430 <foo>:
	8048430:       55                      push   ebp
	8048431:       89 e5                   mov    ebp,esp
	8048433:       83 ec 38                sub    esp,0x38
	8048436:       c7 45 f4 2a 00 00 00    mov    DWORD PTR [ebp-0xc],0x2a
	804843d:       8b 45 08                mov    eax,DWORD PTR [ebp+0x8]
	8048440:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	8048444:       8d 45 e0                lea    eax,[ebp-0x20]
	8048447:       89 04 24                mov    DWORD PTR [esp],eax
	804844a:       e8 b1 fe ff ff          call   8048300 <strcpy@plt>
	804844f:       8b 45 f4                mov    eax,DWORD PTR [ebp-0xc]
	8048452:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	8048456:       c7 04 24 20 85 04 08    mov    DWORD PTR [esp],0x8048520
	804845d:       e8 8e fe ff ff          call   80482f0 <printf@plt>
	8048462:       c9                      leave
	8048463:       c3                      ret

Maintenant, compilons avec SSP (option -fstack-protector-all), et comparons les deux désassemblage :

	:::objdump
	08048480 <foo>:
	8048480:       55                      push   ebp
	8048481:       89 e5                   mov    ebp,esp
	8048483:       83 ec 38                sub    esp,0x38
	8048486:       8b 45 08                mov    eax,DWORD PTR [ebp+0x8]
	8048489:       89 45 d4                mov    DWORD PTR [ebp-0x2c],eax
	804848c:       65 a1 14 00 00 00       mov    eax,gs:0x14
	8048492:       89 45 f4                mov    DWORD PTR [ebp-0xc],eax
	8048495:       31 c0                   xor    eax,eax
	8048497:       c7 45 dc 2a 00 00 00    mov    DWORD PTR [ebp-0x24],0x2a
	804849e:       8b 45 d4                mov    eax,DWORD PTR [ebp-0x2c]
	80484a1:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	80484a5:       8d 45 e0                lea    eax,[ebp-0x20]
	80484a8:       89 04 24                mov    DWORD PTR [esp],eax
	80484ab:       e8 a0 fe ff ff          call   8048350 <strcpy@plt>
	80484b0:       8b 45 dc                mov    eax,DWORD PTR [ebp-0x24]
	80484b3:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	80484b7:       c7 04 24 c0 85 04 08    mov    DWORD PTR [esp],0x80485c0
	80484be:       e8 6d fe ff ff          call   8048330 <printf@plt>
	80484c3:       8b 45 f4                mov    eax,DWORD PTR [ebp-0xc]
	80484c6:       65 33 05 14 00 00 00    xor    eax,DWORD PTR gs:0x14
	80484cd:       74 05                   je     80484d4 <foo+0x54>
	80484cf:       e8 6c fe ff ff          call   8048340 <__stack_chk_fail@plt>
	80484d4:       c9                      leave
	80484d5:       c3                      ret

 

1. Aux adresses 8048486 et 8048489 de la version SSP, on remarque que l'argument de la fonction est recopié sur la pile, avant le buffer. En cas de débordement de celui-ci, nous ne pourrons donc pas écraser l'argument de la fonction.

2. Aux adresses 804848c et 8048492, il s'agit du cookie (valeur contenue dans gs:0x14, qui est généralement une valeur aléatoire) qui est placé sur la pile, entre les variables locales et le saved-ebp et saved-eip : en cas de débordement, le cookie est écrasé et ne correspond plus alors à la valeur présente dans gs:0x14.

À la sortie de la fonction (adresse 80484c6), le cookie est comparé avec la valeur de gs:0x14 : si la valeur a changée (débordement), le programme se termine (fonction __stack_chk_fail) en affichant un message d'erreur.

3. On remarque que dans la version sans SSP, la variable i est placée à ebp-0xc, et le buffer à ebp-0x20. Le buffer est donc placé avant la variable, et un débordement écrasera la variable i.

Dans la version SSP, la variable i est placée à ebp-0x24 alors que le buffer est situé à ebp-0x20 : un débordement ne pourra pas écraser la variable i.

 

Voilà pour le petit aperçu de SSP, il s'agit d'une protection très efficace pour contrer les débordement sur la pile. En revanche elle s'avère inutile dans de nombreux cas : débordements dans un autre segment, cas où on contrôle l'indice d'un buffer, processus forké, débordement dans une structure...

 
## ASLR

C'est l'acronyme de Adress Space Layout Randomization. Il s'agit d'une protection du Noyau Linux qui permet de mapper certaines partie du programme à des adresses aléatoires : ce qui peut rendre l'exploitation de vulnérabilités délicate.

ASLR rends aléatoire l'emplacement des bibliothèques partagées, de la stack et du heap.

Regardons deux exécutions de cat /proc/self/maps pour voir l'effet de l'ASLR :

	:::console
	$ cat /proc/self/maps
	08048000-08053000 r-xp 00000000 08:03 1317757    /usr/bin/cat
	08053000-08054000 r--p 0000a000 08:03 1317757    /usr/bin/cat
	08054000-08055000 rw-p 0000b000 08:03 1317757    /usr/bin/cat
	0857e000-0859f000 rw-p 00000000 00:00 0          [heap]
	b74be000-b7514000 r--p 00000000 08:03 1330849    /usr/lib/locale/locale-archive
	b7514000-b7515000 rw-p 00000000 00:00 0
	b7515000-b76bd000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b76bd000-b76be000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76be000-b76c0000 r--p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c0000-b76c1000 rw-p 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c1000-b76c4000 rw-p 00000000 00:00 0
	b76e3000-b76e4000 rw-p 00000000 00:00 0
	b76e4000-b76e5000 r-xp 00000000 00:00 0          [vdso]
	b76e5000-b7705000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b7705000-b7706000 r--p 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b7706000-b7707000 rw-p 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	bfb72000-bfb93000 rw-p 00000000 00:00 0          [stack]

	$ cat /proc/self/maps
	08048000-08053000 r-xp 00000000 08:03 1317757    /usr/bin/cat
	08053000-08054000 r--p 0000a000 08:03 1317757    /usr/bin/cat
	08054000-08055000 rw-p 0000b000 08:03 1317757    /usr/bin/cat
	09100000-09121000 rw-p 00000000 00:00 0          [heap]
	b74c2000-b7518000 r--p 00000000 08:03 1330849    /usr/lib/locale/locale-archive
	b7518000-b7519000 rw-p 00000000 00:00 0
	b7519000-b76c1000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c1000-b76c2000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c2000-b76c4000 r--p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c4000-b76c5000 rw-p 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b76c5000-b76c8000 rw-p 00000000 00:00 0
	b76e7000-b76e8000 rw-p 00000000 00:00 0
	b76e8000-b76e9000 r-xp 00000000 00:00 0          [vdso]
	b76e9000-b7709000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b7709000-b770a000 r--p 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b770a000-b770b000 rw-p 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	bf969000-bf98a000 rw-p 00000000 00:00 0          [stack]

On remarque que tout est randommisé, à part 3 plages mémoires :

- 08048000-08053000 r-xp  -> segment de CODE

- 08053000-08054000 r--p  -> segment DATA read only

- 08054000-08055000 rw-p -> segment DATA read/write

## NX bit

Il s'agit d'une protection présente également dans le Noyau Linux (les processeur x86_64 intègrent cette protection au niveau matériel) permettant d'empêcher l'exécution de code sur une page mémoire où c'est inutile, tel que la stack.

Voyons le fichier /proc/<PID>/maps avec NX et sans NX activé (On peut désactiver avec -z execstack avec gcc, ou le logiciel execstack) :

	:::console
	$ gcc test.c && ( ./a.out & cat /proc/`pidof a.out`/maps)
	08048000-08049000 r-xp 00000000 08:04 261743     /home/tosh/Test/a.out
	08049000-0804a000 rw-p 00000000 08:04 261743     /home/tosh/Test/a.out
	b75dd000-b75de000 rw-p 00000000 00:00 0
	b75de000-b7786000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b7786000-b7787000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b7787000-b7789000 r--p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b7789000-b778a000 rw-p 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b778a000-b778d000 rw-p 00000000 00:00 0
	b77ac000-b77ad000 rw-p 00000000 00:00 0
	b77ad000-b77ae000 r-xp 00000000 00:00 0          [vdso]
	b77ae000-b77ce000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b77ce000-b77cf000 r--p 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b77cf000-b77d0000 rw-p 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	bff77000-bff98000 rw-p 00000000 00:00 0          [stack]

	$ gcc test.c -z execstack && ( ./a.out & cat /proc/`pidof a.out`/maps)
	08048000-08049000 r-xp 00000000 08:04 261743     /home/tosh/Test/a.out
	08049000-0804a000 rwxp 00000000 08:04 261743     /home/tosh/Test/a.out
	b75c9000-b75ca000 rwxp 00000000 00:00 0
	b75ca000-b7772000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b7772000-b7773000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b7773000-b7775000 r-xp 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b7775000-b7776000 rwxp 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b7776000-b7779000 rwxp 00000000 00:00 0
	b7798000-b7799000 rwxp 00000000 00:00 0
	b7799000-b779a000 r-xp 00000000 00:00 0          [vdso]
	b779a000-b77ba000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b77ba000-b77bb000 r-xp 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b77bb000-b77bc000 rwxp 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	bf9a0000-bf9c1000 rwxp 00000000 00:00 0          [stack]

 

On voit que presque toutes les pages mémoires sont exécutable...

 
## PIE

C'est l'acronyme de Position Independant Executable. Il s'agit pour moi de la suite logique de l'ASLR : les dernières pages mémoires du programme qui n'étaient pas randomisées le sont désormais.

Un programme compilé avec PIE peut être mappé en mémoire à une adresse variable, à la manière des bibliothèques partagées. Il s'agit d'une protection très efficace contre le Return Oriented Programming, étant donné qu'il devient compliqué de prédire l'adresse d'une portion de code.

Voici deux exécutions d'un programme PIE :

	:::console
	$ gcc test.c -fpie -pie && ( ./a.out & cat /proc/`pidof a.out`/maps)
	b75df000-b75e0000 rw-p 00000000 00:00 0
	b75e0000-b7788000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b7788000-b7789000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b7789000-b778b000 r--p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b778b000-b778c000 rw-p 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b778c000-b778f000 rw-p 00000000 00:00 0
	b77ae000-b77af000 rw-p 00000000 00:00 0
	b77af000-b77b0000 r-xp 00000000 00:00 0          [vdso]
	b77b0000-b77d0000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b77d0000-b77d1000 r--p 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b77d1000-b77d2000 rw-p 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	b77d2000-b77d3000 r-xp 00000000 08:04 261743     /home/tosh/Test/a.out
	b77d3000-b77d4000 rw-p 00000000 08:04 261743     /home/tosh/Test/a.out
	bf9ae000-bf9cf000 rw-p 00000000 00:00 0          [stack]

	$ gcc test.c -fpie -pie && ( ./a.out & cat /proc/`pidof a.out`/maps)
	b7528000-b7529000 rw-p 00000000 00:00 0
	b7529000-b76d1000 r-xp 00000000 08:03 1313428    /usr/lib/libc-2.18.so
	b76d1000-b76d2000 ---p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76d2000-b76d4000 r--p 001a8000 08:03 1313428    /usr/lib/libc-2.18.so
	b76d4000-b76d5000 rw-p 001aa000 08:03 1313428    /usr/lib/libc-2.18.so
	b76d5000-b76d8000 rw-p 00000000 00:00 0
	b76f7000-b76f8000 rw-p 00000000 00:00 0
	b76f8000-b76f9000 r-xp 00000000 00:00 0          [vdso]
	b76f9000-b7719000 r-xp 00000000 08:03 1313416    /usr/lib/ld-2.18.so
	b7719000-b771a000 r--p 0001f000 08:03 1313416    /usr/lib/ld-2.18.so
	b771a000-b771b000 rw-p 00020000 08:03 1313416    /usr/lib/ld-2.18.so
	b771b000-b771c000 r-xp 00000000 08:04 261743     /home/tosh/Test/a.out
	b771c000-b771d000 rw-p 00000000 08:04 261743     /home/tosh/Test/a.out
	bfd49000-bfd6a000 rw-p 00000000 00:00 0          [stack]

On voit que cette fois, il n'y a pas une seule plage mémoire qui n'est pas aléatoire !

 
## Read-only relocation

Il s'agit d'une protection mise en place par GCC, permettant de demander au linker de résoudre les fonctions de bibliothèques dynamiques au tout début de l'exécution, et donc de pouvoir remapper la section GOT et GOT.plt en lecture seule.

Voici un exemple de programme compilé avec full RELRO et sans :

	:::c
	#include <stdio.h>
	#include <string.h

	void fake_printf(void) {
    	puts("GOT overwriten !");
	}

	int main(int argc, char **argv) {
    	unsigned int *p = (void*)(strtol(argv[1], NULL, 0));

    	*p = (unsigned int)fake_printf;
    	printf("Overwrite %p : OK !\n", p);

    	return 0;
	}

Testons avec et sans RELRO

	:::console
	$ gcc test.c
	$ readelf -r ./a.out | grep printf
	08049790  00000107 R_386_JUMP_SLOT   00000000   printf
	$ ./a.out 0x08049790
	GOT overwriten !

	 $ gcc test.c -Wl,-z,relro,-z,now
	$ readelf -r ./a.out | grep printf
	08049fe8  00000107 R_386_JUMP_SLOT   00000000   printf
	$ ./a.out 0x08049fe8             
	Erreur de segmentation

On remarque que sans la Read-only relocation, on arrive sans problème à réécrire une entrée de la GOT et donc à changer le cours d'exécution d'un programme.

Ce qui n'est plus possible en activant la protection, comme le montre l'erreur de segmentation.
Grsecurity

Il s'agit d'un patch pour le kernel Linux, renforçant sa sécurité. Pour voir toutes les features de ce patch (il y en a beaucoup), vous pouvez aller visiter cette page : [grsecurity](http://en.wikibooks.org/wiki/Grsecurity/Appendix/Grsecurity_and_PaX_Configuration_Options)

 
## FORTIFY_SOURCE

Là encore, c'est une feature de GCC. Elle permet de remplacer des fonctions dîtes non-sécurisé (tel que strcpy, strcat, sprintf...) par des fonctions sécurisé.

GCC calcule par exemple automatiquement la taille des buffers pour la passer en paramètre des fonctions "sécurisées".

Voici un exemple d'un programme compilé sans FORTIFY_SOURCE et avec (-D_FORTIFY_SOURCE=2) :

	:::objdump
	08048400 <foo>:
	8048400:       83 ec 3c                sub    esp,0x3c
	8048403:       8b 44 24 40             mov    eax,DWORD PTR [esp+0x40]
	8048407:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	804840b:       8d 44 24 1c             lea    eax,[esp+0x1c]
	804840f:       89 04 24                mov    DWORD PTR [esp],eax
	8048412:       e8 b9 fe ff ff          call   80482d0 <strcpy@plt>
	8048417:       83 c4 3c                add    esp,0x3c
	804841a:       c3                      ret

	08048420 <foo>:
	8048420:       83 ec 3c                sub    esp,0x3c
	8048423:       c7 44 24 08 14 00 00    mov    DWORD PTR [esp+0x8],0x14
	804842a:       00 
	804842b:       8b 44 24 40             mov    eax,DWORD PTR [esp+0x40]
	804842f:       89 44 24 04             mov    DWORD PTR [esp+0x4],eax
	8048433:       8d 44 24 1c             lea    eax,[esp+0x1c]
	8048437:       89 04 24                mov    DWORD PTR [esp],eax
	804843a:       e8 d1 fe ff ff          call   8048310 <__strcpy_chk@plt>
	804843f:       83 c4 3c                add    esp,0x3c
	8048442:       c3                      ret

 

On voit que la fonction appelée dans le code compilé avec FORTIFY_SOURCE n'est plus strcpy, mais strcpy_chk, qui prends un paramètre de plus : la taille du buffer.

On voit que gcc calcule automatiquement le dernier paramètre à passer à strcpy_chk.

 
## Sécurité Kernel

Tout au long de cet article, il a été question des protections userspaces. Il y a également bon nombre de sécurité mises en place pour compliquer l'exploitation en mode kernel, tel que : mmap à l'adresse 0x00 interdite, non-exportation des symboles Kernels...

Peut être que j'en détaillerais quelques-unes dans un prochain article... :)

 

 

Voilà, c'est tout pour cet article. J'ai sans doutes oublié de parler de quelques protections, mais il me semble que les principales sont là.

N'hésitez pas à faire une remarque si quelque chose vous semble incorrecte ou incomplet.

Happy Hacking :)

-TOSH-
