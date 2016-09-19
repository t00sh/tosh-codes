---
title: CSAW CTF 2016 - Broken Box
author: Tosh
date: 2016-09-18
tags: ctf,crypto,rsa
layout: post
---

![Challenge](/images/csaw-2016.png)

# Présentation du challenge

Le challenge consiste en un service où l'on peut soumettre des messages à signer avec l'algorithme RSA. Le but du challenge est bien entendu de déchiffrer le flag fourni.

```
Input an number(0~9999) to be signed: 5
signature:13413685168308961198111035418... N:172794691472...
Sign more items?(yes, no):
```

Il est précisé que le hardware du service est vieux et que parfois de mauvaises signatures sont renvoyées.

On peut supposer que lorsque l'on reçoit une mauvaise signature, celà signifie qu'un bit-flip a eu lieu pendant le calcul de la signature.

# Rappels sur la signature RSA

Soit \\(n\\) le produit de deux grands nombres premiers \\(p\\) et \\(q\\),

\\(\varphi(n) = (p-1)(q-1)\\),

\\(e < \varphi(n)\\) tel que \\(PGCD(e, \varphi(n)) = 1\\),

\\(d = {1\over{e}}~(mod~\varphi(n))\\),

\\(d\_p = {1\over{e}}~(mod~(p-1))\\),

\\(d\_q = {1\over{e}}~(mod~(q-1))\\),

\\(m < n\\), le message à signer.

Voici comment est calculé une signature RSA :

$$s = m^{d} (mod~n)$$

Et voici comment peut être vérifiée une signature :

$$m' = s^{e} (mod~n)$$

Si \\(m' = m\\), alors la signature est correcte.

Une optimisation du calcul de la signature, utilise le CRT ([Chinese Rest Theorem](https://fr.wikipedia.org/wiki/Th%C3%A9or%C3%A8me_des_restes_chinois)) :

$$s1 = m^{d_p} (mod~p)$$

$$s2 = m^{d_q} (mod~q)$$

Avec ces deux résultats, il est alors possible de calculer la signature (je ne vais pas détailler ici, il y a déjà plein de documentation sur le sujet).

Si le service avait utilisé cette optimisation, un bit-flip lors du calcul d'une des deux signatures intermédiaires aurait permit de retrouver l'exposant privé grâce au PGCD.

Malheureusement, ce n'était pas de ce côté qu'il fallait chercher...

# Récupération de l'exposant privé

Revenons à notre calcul de signature basique :

$$s = m^{d} (mod~n)$$

Ici, le bit-flip peut avoir lieu à trois endroits différents : sur le \\(m\\), sur le \\(d\\) et sur le \\(n\\).

Si un bit flip intervient sur le \\(d\\), une mauvaise signature notée \\(s\_{invalid}\\) nous sera renvoyée. Celà signifie que le calcul rééllement effectué est le suivant :

$$s_{invalid} = m^{d \pm 2^k} (mod~n)$$

$$\Longleftrightarrow s\_{invalid} = m^{d}*m^{\pm 2^k} (mod~n)$$

$$\Longleftrightarrow s\_{invalid} = s*m^{\pm 2^k} (mod~n)$$

On peut donc facilement deviner un bit de l'exposant \\(d\\), en testant toutes les combinaisons de \\(k\\) jusqu'à satisfaire l'équation précédente (le modulus faisant 1024 bits, on a donc au plus 1024 \\(k\\) à tester pour récupérer un bit de l'exposant).

Si on a rajouté \\(2^k\\), celà signifie que le \\((k+1)^{ième}\\) bit de \\(d\\) était à 0. Si on a enlevé \\(2^k\\), celà veut dire que le \\((k+1)^{ième}\\) bit de \\(d\\) était à 1.

On a tout ce qu'il faut maintenant pour réaliser l'exploit permettant de récupérer tous les bits de l'exposant privé \\(d\\).

Voici l'exploit Python :

```python
#!/usr/bin/python

import socket
import sys
import re
from gmpy2 import *
from binascii import *

D_SIZE = 1024
S = 97
E = 0x10001
FLAG = int(open('flag.enc').read())

HOST = 'crypto.chal.csaw.io'
PORT = 8002

def connect_to_serv(host, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((host, port))
    except:
        print "[-] Failed to connect to server"
        sys.exit(1)
    return sock

def sign_number(sock, num):

    while True:
        data = sock.recv(2048)

        if not data:
            return None

        if re.search("more items", data):
            sock.send("yes\n")

        if re.search("Input an number", data):
            sock.send(str(num) + "\n")

        m = re.match("signature:(\d+), N:(\d+)", data)
        if m != None:
            (s, n) = m.groups()
            return (int(s), int(n))

    return (None, None)

def get_valid_sig(sock):
    (sig, N) = sign_number(sock, S)
    while powmod(sig, E, N) != S:
        (sig, N) = sign_number(sock, S)
    return (sig, N)

def get_bad_sig(sock):
    (sig, N) = sign_number(sock, S)

    return sig

def get_k(sig_v, sig_i, N):

    for k in xrange(D_SIZE):
        s = (sig_v * powmod(S, 2**k, N)) % N
        if s == sig_i:
            return (1, k)
        s = (sig_v * powmod(S, -(2**k), N)) % N
        if s == sig_i:
            return (0, k)

    return (None, None)

def compute_d(d_lst):
    d = 0
    k = 0

    for x in d_lst:
        d += x * (2**k)
        k += 1

    return d

def bf_d(sock, sig_v, N):
    done = 0
    c = [0 for i in xrange(D_SIZE)]
    d = [0 for i in xrange(D_SIZE)]

    while done < D_SIZE:

        print "".join(map(str, c))
        print "".join(map(str, d))

        print "Done = %d/%d" % (done, D_SIZE)

        try:
            sig_i = get_bad_sig(sock)
        except:
            continue

        (sign, k) = get_k(sig_v, sig_i, N)

        print "K = ", k

        if k == None:
            continue

        if c[k] == 0:
            done = done + 1
            c[k] = 1

        if sign == 1:
            d[k] = 0
        else:
            d[k] = 1

    return compute_d(d)


sock = connect_to_serv(HOST, PORT)

(sig_v, N) = get_valid_sig(sock)

d = bf_d(sock, sig_v, N)
print "D = ", d

flag = powmod(FLAG, d, N)
print "Flag = ", unhexlify("%x" % flag)
```

On obtient alors le flag : flag{br0k3n\_h4rdw4r3\_l34d5\_70\_b17\_fl1pp1n6}