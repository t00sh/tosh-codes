---
title: Hack.lu CTF 2016 - Cornelius 1 (crypto 200)
author: Tosh
date: 2016-10-20
tags: ctf,crypto,deflate,CTR
layout: post
---

Voici ma solution pour le challenge *Cornelius 1* du Hack.lu CTF, auquel j'ai participé avec la team [0x90r00t](https://0x90r00t.com).

Vous pouvez trouver la source du challenge dans mon [dépôt](https://repo.t0x0sh.org/ctf/2016/hacklu/cornelius-1.rb.txt).

Ici, le problème est que l'on compresse les données avec [deflate](https://fr.wikipedia.org/wiki/Deflate) avant de les chiffrer avec un mode CTR. On peut donc utiliser une attaque du même principe que [CRIME](https://en.wikipedia.org/wiki/CRIME), pour deviner petit à petit le flag.

En effet, lorsque plusieurs chaînes de caractères se répètent, l'algorithme [deflate](https://fr.wikipedia.org/wiki/Deflate) utilise ces répétitions pour diminuer la taille des données compressées.

Le serveur nous renvoit le résultat de :

```
CTR(deflate("[username, flag:"flag=le_flag_a_deviner"]"))
```

Puisque l'on contrôle complétement la chaîne *username*, lorsque l'on reçoit des données plus courtes que d'autres on peut donc deviner que notre chaîne utilisateur se répète dans le *flag*, et récupérer petit à petit tous les caractères de ce dernier.


Voici l'exploit final :

```python
import urllib.request
import binascii
import base64

URL = "https://cthulhu.fluxfingers.net:1505/?user=%s"

def get_cookie(url, user):
    url = url % urllib.parse.quote(user)
    d = urllib.request.urlopen(url)

    return base64.b64decode(d.getheader('Set-Cookie')[5:])

charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_:{}"

def bf(flag):

    print(flag)

    lengths = {}

    for c in charset:
        l = len(get_cookie(URL, (flag + c + "-") * 10))

        if l not in lengths:
            lengths[l] = [c]
        else:
            lengths[l].append(c)

    keys = sorted(lengths.keys())

    if len(keys) > 1:
        for c in lengths[keys[0]]:
            print("Candidates: %s" % lengths[keys[0]])
            bf(flag + c)

bf('flag:')
```
