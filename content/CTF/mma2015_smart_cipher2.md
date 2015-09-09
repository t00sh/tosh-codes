Title: [MMA 2015] Smart Cipher 2 (crypto 10)
Date: 2015-09-08
Tags: ctf,crypto
Author: Tosh
Summary: MMA CTF write-up

Voici un petit write-up pour le challenge Smart Cipher (flag2), du CTF MMA 2015.

Nous avons un message chiffré : e3 e3 83 21 33 96 23 43 ef 9a 9a 05 18 c7 23 07 07 07 c7 9a 04 33 23 07 23 ef 12 c7 04 96 43 23 23 18 04 04 05 c7 fb 18 96 43 ef 43 ff

Il s'agit d'une attaque à texte clairs choisis (on peut chiffrer les messages que l'on souhaites), sur un algorithme inconnu.


On se rend compte assez vite qu'il s'agit d'un chiffrement pas substitution mono-alphabétique. N'ayant pas trouvé de logique dans les substitutions, j'ai récupéré toutes les combinaisons de clairs => chiffrés des caractères ASCII avec le programme suivant :


```
    #!/usr/bin/perl

    use strict;

    for(my $i = 0x30; $i <= 0x7d; $i++) {
        my $c = chr($i);
        my @resp = `curl -X POST -F "s=$c" http://bow.chal.mmactf.link/%7Escs/crypt4.cgi`;

        foreach(@resp) {
            if(m/h1>(\S+) <form methode=/) {
                print "0x$1 => \'$c\',\n";
            }
        }
    }
```

On a plus qu'à déchiffrer le message avec la table de substitution récupérée :


```
    #!/usr/bin/perl
    use strict;
    use warnings;

    my @flag = map {hex "0x" . $_} qw(e3 e3 83 21 33 96 23 43 ef 9a 9a 05 18 c7 23 07 07 07 c7 9a 04 33 23 07 23 ef 12 c7 04 96 43 23 23 18 04 04 05 c7 fb 18 96 43 ef 43 ff);

    my %sbox = (
        0x04 => '0',
        0xc7 => '1',
        0x23 => '2',
        0xc3 => '3',
        0x18 => '4',
        0x96 => '5',
        0x05 => '6',
        0x9a => '7',
        0x07 => '8',
        0x12 => '9',
        0x80 => ':',
        0xe2 => ';',
        0x27 => '=',
        0xb2 => '>',
        0x75 => '?',
        0x83 => 'A',
        0x2c => 'B',
        0x1a => 'C',
        0x1b => 'D',
        0x6e => 'E',
        0x5a => 'F',
        0xa0 => 'G',
        0x52 => 'H',
        0x3b => 'I',
        0xd6 => 'J',
        0xb3 => 'K',
        0x29 => 'L',
        0xe3 => 'M',
        0x2f => 'N',
        0x84 => 'O',
        0x53 => 'P',
        0xd1 => 'Q',
        0x00 => 'R',
        0xed => 'S',
        0x20 => 'T',
        0xfc => 'U',
        0xb1 => 'V',
        0x5b => 'W',
        0x6a => 'X',
        0xcb => 'Y',
        0xbe => 'Z',
        0x39 => '[',
        0x4c => ']',
        0x58 => '^',
        0xcf => '_',
        0xef => 'a',
        0xaa => 'b',
        0xfb => 'c',
        0x43 => 'd',
        0x4d => 'e',
        0x33 => 'f',
        0x85 => 'g',
        0x45 => 'h',
        0xf9 => 'i',
        0x02 => 'j',
        0x7f => 'k',
        0x50 => 'l',
        0x3c => 'm',
        0x9f => 'n',
        0xa8 => 'o',
        0x51 => 'p',
        0xa3 => 'q',
        0x40 => 'r',
        0x8f => 's',
        0x92 => 't',
        0x9d => 'u',
        0x38 => 'v',
        0xf5 => 'w',
        0xbc => 'x',
        0xb6 => 'y',
        0xda => 'z',
        0x21 => '{',
        0x10 => '|',
        0xff => '}',

    );

    foreach(@flag) {

        if(!exists($sbox{$_})) {
            print "?";
        } else {
            print $sbox{$_};
        }
    }

    print "\n";
```

Le flag :

MMA{f52da776412888170f282a9105d2240061c45dad}