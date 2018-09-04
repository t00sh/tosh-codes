---
title: Tokyo Western CTF - Revolutionnal Secure Angou
author: Tosh
date: 2018-09-03
tags: ctf,tokyo,crypto,rsa
layout: post
---

In this challenge we get an [RSA public key](https://repo.t0x0sh.org/ctf/2018/tokyo-western/revolutional-secure-angou/publickey.pem), an [encrypted flag](https://repo.t0x0sh.org/ctf/2018/tokyo-western/revolutional-secure-angou/flag.encrypted) and a [Ruby script](https://repo.t0x0sh.org/ctf/2018/tokyo-western/revolutional-secure-angou/generator.rb.txt).

If we analyse the Ruby script, we can see a modified RSA algorithm for the key generation. It uses the public exponent \\(e = 65537\\) and generate a random \\(1024\\) bits prime \\(p\\).

Then, and the vulnerability is here, the script generate the \\(q\\) as the inverse of \\(e~mod~p\\) and loop, until \\(q\\) is not prime. If we look the equations, we have :

$$eq \equiv 1~(mod~p)$$

So there exists an integer \\(k\\) such as $$eq = 1 + kp$$.

If we multiply both sides with \\(p\\), we get :

$$eqp = p + kp^{2}$$

$$\iff en = p + kp^{2}$$

$$\iff kp^{2} + p - en = 0$$

As you can see, it's a quadratic equation with two unknowns (the \\(p\\) and the \\(k\\)). For the \\(k\\), if we look at the equation \\(eq = 1 + kp\\), we know that \\(q < p\\) because \\(q\\) it's an inverse modulo \\(p\\). It implies \\(k < e\\).

Now, we can just iterates over all possibles \\(k\\) and try to solve the quadratic equation with only the \\(p\\) unknown. We can stop when \\(p|n\\) and \\(p\\) is not a trivial factor.

I used gmpy2 to calculate an integer square root and solve the equation. The script to recover \\(p\\) and \\(q\\) can be found here : [sploit](https://github.com/t00sh/ctf/blob/master/2018/tokyo-western/revolutional-secure-angou/sploit.py).

Once the \\(n\\) is factorised, I used [this C program](https://github.com/t00sh/misc/blob/master/crypto/gen_rsa_privkey.c) to generate the private key at PEM format, and finally used openssl to decrypt the flag :

```console
$ openssl rsautl -inkey private.pem -decrypt < flag.encrypted
TWCTF{9c10a83c122a9adfe6586f498655016d3267f195}
```
