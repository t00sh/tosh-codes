---
title: Tokyo Western CTF - Mixed Cipher
author: Tosh
date: 2018-09-03
tags: ctf,tokyo,crypto,rsa,aes,cbc
layout: post
---

In this challenge, we have a remote service written in Python where the [script](https://repo.t0x0sh.org/ctf/2018/tokyo-western/mixed-cipher/server.py.txt) is given.

It's an hybrid cryptosystem using RSA and AES-CBC. When the service start, a symetric AES key is generated with `os.urandom`. An RSA keypair is also generated with a 1024 bits modulus and 65537 as the public exponent. The modulus is kept secret by the service.

You can do several things with this service :

- Encrypt messages with RSA and AES-CBC

- Decrypt RSA messages : only the 8 LSB of the decrypted message are sent.

- Get the AES encrypted flag without the IV.

- Get the AES encrypted key with RSA.

# First step : getting the modulus

The first step is to recover the modulus of the RSA public key. To achieve that, we can use the _encrypt_ primitive with two differents messages \\(m\\) and \\(m'\\).

If we get $$c \equiv m^{e}~mod~n$$ and $$c' \equiv m'^{e}~mod~n$$ then we have

$$n | m^e - c~~~~ and ~~~~~~n | m'^e - c'$$

There is a high probability that \\(gcd(m^e-c, m'^e-c')\\) give us the modulus with a low factor. This step could be slow, because \\(m^e\\) and \\(m'^e\\) are large (I tried to take the smallest messages).

# Second step : finding the AES key

Now, we can use the **decrypt** primitive to find the AES key used. Because the server gives us the LSB of the decrypted message and no padding is used, we can turn the primitive to an LSB oracle.

We use the encrypted key as the base message, and multiply by \\(2^e\\) at each step. Because the RSA algorithm is homomorphic, the resulted plaintext given to oracle is also multiplied by two.

At step \\(i\\), if the plaintext LSB is even, then we know that $$2(2^{i-1}key~mod~n) < n$$ and if plaintext LSB is odd, $$2(2^{i-1}key~mod~n) > n$$

We can do a binary research, and divide upper bound by two in the first case, and divide the lower bound by two in the second case. We have a \\(log_2(n)\\) algorithm to recover the AES key.

# Third step : finding the AES IV

The problem now, is the random IV used at each call of the **get\_flag** function. It's impossible to decrypt the first bloc of the ciphertext without the IV.

If we read the script carefully (thanks ekt0plasm), we can see that the IV is generated with a weak pseudo-random generator : the Mersenne Twister PRNG used internaly in the `random.getrandbits()` function.

If we get enough IV (156) it is then possible to reconstruct the state of the generator, and predict the next IV.

For this step, I used this [Python library](https://github.com/eboda/mersenne-twister-recover) to predict the next IV. We can then call **encrypt** function 156 times, and pass all the IV to this library.

We can then predict the next IV used to encrypt our flag.

# Decrypt the flag

Now, we have the AES key and the IV, it's now trivial to flag the challenge !

You can find [my full exploit](https://github.com/t00sh/ctf/blob/master/2018/tokyo-western/mixed-cipher/sploit.py) on my github. Do not forget to clone the [Mersenne Twister Recover library](https://github.com/eboda/mersenne-twister-recover) if you want the script working.
