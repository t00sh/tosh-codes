---
layout: page
title: Projects
permalink: /projects/
---

You can find my different projects in my [Github](https://github.com/t00sh) account.

# [py-ecdsa](https://github.com/t00sh/py-ecdsa)

py-ecdsa is a small library used to sign and verify ECDSA signatures. The NIST curves P-192, P-224, P-384, P-521 from FIPS-186-4 are implemented. This library is for testing purpose, and shouldn't not be used in any critical application.

# [rop-tool](https://github.com/t00sh/rop-tool)

rop-tool is a little tool to help you write binary exploits. It can find gadgets for rop chains, search string, trace heap allocations, disassemble code, and more...

# [perl-keystone](https://github.com/t00sh/perl-keystone)

Keystone is a lightweight multi-platform, multi-architecture assembler framework. Perl-keystone is a Perl binding which allow you to use the keystone library into your Perl scripts.

# [perl-capstone](https://github.com/t00sh/perl-capstone)

Capstone is a lightweight multi-platform, multi-architecture (ARM, MIPS, X86...) disassembly framework. Perl-capstone is a Perl binding which allow you to use the capstone library into your Perl scripts.

Note: only basics features of capstone are implemented for now.

# [sc-make](https://github.com/t00sh/sc-make)

Sc-make takes an assembly file (with Nasm syntax) and output the shellcode's bytes formated into many format (Perl, Python, C...).

Sc-make uses Nasm and Objdump.

# [elf-poison](https://github.com/t00sh/elf-poison)

This is an ELF-injector which uses two tricks to inject code into an ELF file.

The first one creates a new ELF section for the "shellcode", and redirect the entry point to it.

The second method injects the shellcode into "dead code" produced by the compiler. The shellcode is then splited in chunks before to be inserted and linked together in the "dead code".

Note: this is only for proof of concept : a lot of features are missing to create a powerfull ELF injector.

# Other projects

I contribute time to time to the [root-me](https://www.root-me.org) plateform by submiting new challenges or writes-up and I also contributed to some open-source projects.

I am currently working on an incomming project : I started the developement of a portable library for easly manipulate different executable formats (PE, ELF, Mach-O...) via a generic interface.
