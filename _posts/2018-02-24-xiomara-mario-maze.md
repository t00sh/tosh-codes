---
title: Xiomara CTF 2018 - Mario in maze
author: Tosh
date: 2018-02-24
tags: ctf,programmation,misc,xiomara
layout: post
---

This year, my team 0x90r00t finished 3rd at the Xiomara CTF. Here is a write-up for the "Mario in maze" challenge, a programming challenge (MISC) offering 150 points.

We had access to a service (139.59.28.4:1340) and had to solve 10 levels to get the flag. Each level consists of a 2D matrix n*m, and a list of checkpoints. We have to find a path in the matrix from (0,0) to (n,m) maximizing the sum of the matrix's visited cells. We can only move to right or bottom direction.

Another constraint is to visit every checkpoints given. At a first try I developed a recursive algorithm, but it was too slow on larges matrix.

So I developed a second solution with [dynamic programming](https://en.wikipedia.org/wiki/Dynamic_programming) paradigm. Here is my solution in Python (important function is solve_matrix) :

```python
from pwn import *

def solve_matrix(matrix, cp):
    r = len(matrix)
    c = len(matrix[0])

    matrix_mem = [[0 for _ in range(c)] for _ in range(r)]
    matrix_mem[0][0] = matrix[0][0]

    # We give a high value to each checkpoint
    for i in range(r):
        for j in range(c):
            if len(filter(lambda x: x == (i, j), cp)) > 0:
                matrix_mem[i][j] += 10000

    for i in range(1, r):
        matrix_mem[i][0] += matrix_mem[i-1][0] + matrix[i][0]
    for j in range(1, c):
        matrix_mem[0][j] += matrix_mem[0][j-1] + matrix[0][j]

    for i in range(1, r):
        for j in range(1, c):
            mij = matrix[i][j]
            mi = matrix_mem[i-1][j]
            mj = matrix_mem[i][j-1]
            matrix_mem[i][j] += max(mi, mj) + mij

    # Don't count checkpoint special value
    return matrix_mem[r-1][c-1] - 10000 * len(cp)

def solve_level(p):
    p.recvuntil(" ]\n")
    (r, c) = p.recvuntil("\n").split(" x ")
    r = int(r)
    c = int(c)

    matrix = [[0 for _ in range(c)] for _ in range(r)]
    for i in range(r):
        l = p.recvline().split(" ")
        for j in range(c):
            matrix[i][j] = int(l[j])

    checkpoints = int(p.recvline())
    cp = []
    for i in range(checkpoints):
        l = p.recvline().split(" ")
        cp.append((int(l[0])-1, int(l[1])-1))

    return solve_matrix(matrix, cp)


if __name__ == "__main__":
    p = remote('139.59.28.4', 1340)
    for i in range(1, 11):
        log.info("Solving level %d..." % i)
        s = solve_level(p)
        log.info("Soluce: %d" % s)
        p.sendline(str(s))
    p.interactive()
```

And we got :

```
[+] Opening connection to 139.59.28.4 on port 1340: Done
[*] Solving level 1...
[*] Soluce: 2364
[*] Solving level 2...
[*] Soluce: 3153
[*] Solving level 3...
[*] Soluce: 5792
[*] Solving level 4...
[*] Soluce: 4133
[*] Solving level 5...
[*] Soluce: 6830
[*] Solving level 6...
[*] Soluce: 4577
[*] Solving level 7...
[*] Soluce: 3091
[*] Solving level 8...
[*] Soluce: 2871
[*] Solving level 9...
[*] Soluce: 2877
[*] Solving level 10...
[*] Soluce: 3884
[*] Switching to interactive mode
Congrats the flag is xiomara{recursion_is_better_than_iteration}
[*] Got EOF while reading in interactive
```