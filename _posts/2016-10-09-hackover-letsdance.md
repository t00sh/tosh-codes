---
title: Hackover CTF 2016 - Letsdance (crypto)
author: Tosh
date: 2016-10-09
tags: ctf,crypto,nonce,nacl
layout: post
---

Voici ma solution pour le challenge *Letsdance* du Hackover CTF, auquel j'ai participé avec la team [0x90r00t](https://0x90r00t.com).

![Letsdance](/images/hackover-2016.png)

Dans ce challenge, on nous fourni un service ainsi que le [code source](https://repo.t0x0sh.org/CTF/HACKOVER_2016/letsdance.py) du service en question.

Le service accepte plusieurs commandes :

- *encrypt* : pour chiffrer un message (dans une session, tous les clairs doivent être différents)

- *decrypt* : pour déchiffrer un message (qui doit être différent d'un des clairs déjà chiffré)

- *execute* : pour exécuter une commande (inutile)

- *gimmeflag* : pour récupérer le flag chiffré.

Au niveau cryptographique, c'est la bibliothèque [NaCl](https://en.wikipedia.org/wiki/NaCl_(software)) qui est utilisée avec la secretbox. Il s'agit d'un chiffrement qui utilise [Chacha20](https://en.wikipedia.org/wiki/Salsa20) pour la confidentialité et [Poly1305](https://en.wikipedia.org/wiki/Poly1305) pour l'intégrité.

Pour chiffrer un message, la secretbox utilise un [nonce](https://fr.wikipedia.org/wiki/Nonce_cryptographique) qui doit être unique pour chaque message chiffré avec la même clef.

Ici, le service utilise un générateur de nonce custom, donc voici la fonction :

```python
def get_nonce():
    random.seed(int(time.time()))
    rb = ord(os.urandom(1))
    rt = random.randint(0, (1<<32)-1)
    rp = os.getpid()
    a = rb << 16 | rp
    b = 0x811f952e
    c = rb << 16 | (rt & 0xffff)
    d = ((rt >> 16) << 16) | rb
    e = 0xdc8ade13
    f = 0xa3c78eeb
    for i in range(10):
        f ^= lr(c + b, 2)
        e ^= lr(a + d, 11)
        d ^= lr(c + e, 7)
        c ^= lr(b + a, 13)
        b ^= lr(f + d, 17)
        a ^= lr(b + e, 5)
    return struct.pack('>IIIIII', a, b, c, d, e, f)
```

Si on analyse un peu cette fonction, on remarque que ce qui varie entre chaque session sont un entier 8 bits *rb* généré par os.urandom() et un entier 32 bits *rt* généré par random.randint().

Or, le générateur pour *rt* est réensemmencé à chaque appel à get\_nonce avec la fonction time()...Celà signifie que si deux appels à get\_nonce() se font dans la même seconde, *rt* aura la même valeur dans les deux appels.

Dans deux appels de get\_nonce() suffisamment rapprochés, il y a donc seulement 8 bits du nonce qui changent... On peut donc facilement trouver une collision, et avoir ainsi deux messages chiffrés avec 2 nonces identiques.

Le keystream généré par [Chacha20](https://en.wikipedia.org/wiki/Salsa20) à partir de la même clef et du même nonce sera donc identique à chaque fois. Si on chiffre deux messages avec le même keystream on aura alors :

$$Keystream = Chacha20(key, nonce)$$
$$C\_{1} = P\_{1} \oplus Keystream$$
$$C\_{2} = P\_{2} \oplus Keystream$$
$$C\_{1} \oplus C\_{2} = P\_{1} \oplus P\_{2}$$

À partir de là, on peut facilement retrouver le message clair correspondant à un des deux messages. Si par exemple, on connait \\(P\_1\\), \\(C\_1\\) et \\(C\_2\\), il est trivial de retrouver \\(P_2\\).

L'idée est donc de trouver une collision avec le nonce ayant servit à chiffrer le FLAG, ce qui permet alors de le déchiffrer de manière immédiate.

À noter également, lorsque l'on chiffre un message avec la secretbox on reçoit :

```
NONCE || MAC || CIPHER
```

Avec un nonce de 24 bytes, un mac de 16 bytes et un cipher de taille variable. On peut donc facilement extraire le nonce du message pour le comparer.

Voici l'exploit python complet :

```python
#!/usr/bin/python2.7

import random
import sys
import socket
import base64
import binascii

HOST = 'challenges.hackover.h4q.it'
#HOST = '127.0.0.1'
PORT = 16335


def connect_to_serv(host, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((host, port))
    except:
        print "[-] Failed to connect to server"
        sys.exit(1)
    return sock

def encrypt(sock, msg):
    sock.send("encrypt\n")
    sock.send(base64.b64encode(msg) + "\n")

    while True:
        data = sock.recv(2048)

        if data is None or data == "":
            sys.exit(0)

        for l in data.split("\n"):
            if len(l) > 80:
                return l

def get_flag(sock):
    sock.send("gimmeflag\n")

    while True:
        data = sock.recv(2048)

        if data is None or data == "":
            sys.exit(0)
        for l in data.split("\n"):
            if len(l) > 80:
                return l

def decrypt_flag(cipher, flag, plain):
    f = ""
    for i in xrange(len(cipher)):
        f += chr(ord(cipher[i]) ^ ord(flag[i]) ^ ord(plain[i]))

    return f

print "[+] Connect to %s:%d" % (HOST, PORT)
sock = connect_to_serv(HOST, PORT)


charset =  [chr(ord('a')+i) for i in xrange(26)]
charset += [chr(ord('A')+i) for i in xrange(26)]
charset += [chr(ord('0')+i) for i in xrange(10)]

print "[+] Finding a nonce collision..."

for i in charset:
    for j in charset:
        flag = base64.b64decode(get_flag(sock))

        flag_nonce = flag[:24]
        flag = flag[40:]

        plain = "A"*32 + i+j

        c = encrypt(sock, plain)
        c = base64.b64decode(c)

        nonce = c[:24]
        cipher = c[40:]

        if flag_nonce == nonce:
            print "[+] Collision found !"
            print " * Nonce          : %s" % binascii.hexlify(nonce)
            print " * Plain          : %s" % binascii.hexlify(plain)
            print " * Cipher         : %s" % binascii.hexlify(cipher)
            print " * Flag encrypted : %s" % binascii.hexlify(flag)

            flag = decrypt_flag(cipher, flag, plain)

            print " * Flag           : %s" % flag

            sys.exit(0)
```

Et on obtient :

```
[+] Connect to challenges.hackover.h4q.it:16335
[+] Finding a nonce collision...
[+] Collision found !
 * Nonce          : 42eab3ded6a2bd67fdd4fdbc3864e155513e3b55376f01b7
 * Plain          : 41414141414141414141414141414141414141414141414141414141414141416250
 * Cipher         : e923a4a69837696c3c14500ffd13f06873abc9e9e69dac302b58cd6d4b6e8159d36b
 * Flag encrypted : c003868cb6004d5f4c636a0add3cd24c7182e9ebcfbdba181e71cd7f621cac748e46
 * Flag           : hackover16{DanceChaChaWithASh3ll?}
```