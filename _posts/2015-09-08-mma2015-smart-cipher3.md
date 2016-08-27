---
title: MMA CTF 2015 - Smart Cipher 3 (crypto 30)
date: 2015-09-08
tags: ctf,crypto
author: Tosh
layout: post
---

Voici un petit write-up pour le challenge Smart Cipher (flag3), du CTF MMA 2015.

Nous avons un message chiffré : 60 00 0c 3a 1e 52 02 53 02 51 0c 5d 56 51 5a 5f 5f 5a 51 00 05 53 56 0a 5e 00 52 05 03 51 50 55 03 04 52 04 0f 0f 54 52 57 03 52 04 4e

Il s'agit d'une attaque à texte clairs choisis (on peut chiffrer les messages que l'on souhaites), sur un algorithme inconnu.

En analysant le comportement des messages chiffrés, on arrive à déduire que le chiffrement ressemble à quelque chose comme :


```Python

def f1(c):
    if c % 2:
        return c+1
    return c-1

def encrypt(msg):
    msg[0] = f2(msg[0]);

    for i in range(1, len(msg)):
        msg[i] = f1(msg[i-1]) ^ f1(msg[i])
```

Je n'ai pas vraiment réussi à comprendre la fonction f2, mais j'avais l'impression que la taille du message était rajouté, avec quelques nuances... Mais je n'en ai pas eu besoin, car en supposant que le flag commence par MMA{, on sait que la première lettre est 'M', et on peut alors initialiser l'algorithme de déchiffrement.

Cet algorithme est inversible, et voici le code Perl implémentant le déchiffrement :


```
    #!/usr/bin/perl
    use strict;
    use warnings;


    my $s = shift || exit;

    print decrypt($s);

    sub decrypt {
        my $s = shift;
        my @cipher;

        foreach my $c($s =~ m/\S\S/g) {
            push @cipher, hex("0x" . $c);
        }

        if(scalar(@cipher) % 2 == 0) {
            $cipher[0] += scalar(@cipher) + 1;
        } else {
            $cipher[0] += scalar(@cipher) - 1;
        }

        $cipher[0] = 0x4D-1;

        for(my $i = 1; exists $cipher[$i]; $i++) {
            $cipher[$i] ^= $cipher[$i-1];
            $cipher[$i] &= 0xFF;
        }

        @cipher = map {calc_letter_rev($_)} @cipher;

        return join('', map { chr } @cipher);
    }

    sub calc_letter_rev {
        my $l = shift;

        return $l - 1 if($l % 2 == 1);
        return $l + 1;
    }

```

On obtient le flag : MMA{e75fd59d2c9f9c227d28ff412c3fea3787c1fe73}