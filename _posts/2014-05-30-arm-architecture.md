---
title: ARM - architecture & assembleur
date: 2014-05-30
tags: raspberry,arm,architecture,assembler
author: Tosh
layout: post
---

# Introduction

Les architectures ARM (Advanced RISC Machines), sont un type de processeur présent maintenant sur de nombreux composants embarqués. (téléphones, tablettes, routeurs...)

De la version ARMv3 à ARMv7, il s'agissait d'architecture 32 bits, mais depuis ARMv8 sont arrivé les architectures 64 bits.

Dans cet article, il sera question d'ARMv6 (32 bits), qui est la version présente sur le Raspberry PI.

Dans un premier temps, je décrirai rapidement les différents modes dans lequel un CPU ARM peut s'exécuter.

Puis, dans une seconde partie, je présenterai les différents registres généraux que l'on peut utiliser dans le mode User.

Ensuite, une troisième partie sera consacrée au fonctionnement de la Pile sur l'architecture ARM.

L'avant-dernière partie traitera du jeu d'instruction ARM.

Et finalement, l'article se terminera sur les appels de fonctions en ARM, et tentera de montrer comment est traduit un code C en assembleur grâce au compilateur GCC.


# Les modes d'exécution

Il y a **9 modes** dans lequel un CPU ARM peut s'exécuter :

- **Le mode user** : Un mode non-privilégié dans lequel la plupart des programmes s'exécutent. (Il ne sera question que de ce mode dans le reste de l'article)

- **Le mode FIQ** : Un mode privilégié dans lequel le processeur entre lorsqu'il accepte une interruption FIQ. (interruption à priorité elevée)

- **Le mode IRQ** : Un mode privilégié dans lequel le processeur entre lorsqu'il accepte une interruption IRQ. (interruption à priorité normale)

- **Le mode Supervisor** : Un mode protégé pour le système d'exploitation.

- **Le mode Abort** : Un mode privilégié dans lequel le processeur entre lorqu'une exception arrive.

- **Le mode Undefined** : Un mode privilégié  dans lequel le processeur entre lorsqu'une instruction inconnue est exécutée.

- **Le mode System** : Le mode dans lequel est exécuté le système d'exploitation.

- **Le mode Monitor** : Ce mode a été introduit pour supporter l'extension TrustZones.

- **Le mode Hypervisor** : Ce mode est utilisé pour ce qui concerne la virtualisation.


# Les registres

Il y a **16 registres**  pouvant être utilisés dans le mode utilisateur (le mode dans lequel les programmes sont exécutés).
Sur ARMv6, tous ces registres sont des registres 32 bits.

- Les registres **r0** à **r10** sont les registres généraux, pouvait être utilisés pour n'importe quelle opération.

- Le registre **r11** (fp) est le "frame pointer", il sert à indiquer le début du contexte de la fonction en cours. (comme ebp sur x86)

- Le registre **r12** (ip) est l'"intraprocedure register", il sert à stocker temporairement des données lorsque l'on passe d'une fonction à une autre.

- Le registre **r13** (sp) est le "stack pointer", il indique le haut de la pile. (comme esp sur x86)

- Le registre **r14** (lr) est le "link register", il sert à stocker l'addresse de retour lorsqu'une fonction est appelée avec l'instruction "branch with link" (cf plus bas)

- Le registre **r15** (pc) est le "program counter", il contient l'addresse de la prochaine instruction à exécuter.

- Le registre **cpsr** pour "current program status register", est un registre spécial mis à jour par le biais de différentes instructions. Il est utilisé par exemple par les instructions conditionnelles, et stock le mode d'exécution actuel.


# La pile

L'architecture ARM possède une pile, tout comme l'architecture x86. Celle-ci est par contre beaucoup plus flexible, car le programme peut choisir la façon dont celle-ci fonctionne.

Il existe 4 types de piles :

- **Pile ascendante** : Lorsque l'on dépose une valeur sur la pile, celle-ci grandit vers les adresse hautes. Le registre **sp** pointe sur la dernière valeur de la pile.

- **Pile descendante** : Lorsque l'on dépose une valeur sur la pile, celle-ci grandit vers les adresses basses. Le registre **sp** pointe sur la dernière valeur de la pile. (C'est généralement ce comportement que l'on retrouve dans la plupart des programmes)

- **Pile ascendante vide** : Tout comme la pile ascendante, la pile grandit vers les adresses hautes. Par contre, le registre **sp** pointe sur une entrée vide de la pile.

- **Pile descendante vide** : Fonctionne comme la pile descendante, sauf que le registre **sp** pointe sur une entrée vide de la pile.

Voici une image pour mieux comprendre :

![Piles ARM](/images/arm-stacks.png)



# Jeu d'instructions

Une instruction ARMv6 est tout le temps codé sur **32 bits** (ou 16 bits pour le THUMB mode, cf plus bas). Voici à quoi ressemble une instruction ARM :

```nasm
    0x18bd8070  ->  popne   {r4, r5, r6, pc}
```

À noter que contrairement à l'x86, toutes les instructions ARM doivent avoir leurs addresse alignée sur 4 bytes (ou 2 bytes pour le THUMB mode).

---------------------------------------------

## Mnémoniques conditionnels

Presque chaque instruction ARM peut être exécuté (ou non) suivant une condition. Voici la liste des mnémonique :

- **eq** : égal

- **ne** : pas égal

- **cs/hs** : plus grand ou égal (non-signé)

- **cc/lo** : plus petit (non-signé)

- **hi** : plus grand (non-signé)

- **ls** : plus petit ou égal (non-signé)

- **mi** : négatif

- **pl** : positif ou nul

- **vs** : overflow

- **vc** : pas d'overflow

- **ge** : plus grand ou égal (signé)

- **lt** : plus petit (signé)

- **gt** : plus grand (signé)

- **le** : plus petit ou égal (signé)

- **al** : toujours vrai

----------------------------------

## Instructions arithmétiques

- Syntaxe : **op{cond}{s} Rd, Rs, Operand**

- op est un mnémonique parmis : **add, sub, rsb, adc, sbc, rsc**

- cond est un mnémonique conditionnel. (optionnel)

- s indique si le registre cpsr est modifié par l'instruction. (optionnel)

- Rd est le registre de destination

- Rs est le registre source

- Operand peut être un registre ou une constante.

- Exemples

```nasm
        addeq r0, r0, #42   ; Ajoute 42 à r0 (si égal)
        subs r1, r2, r3     ; Stock le résultat de r2-r3 dans r1 (cpsr modifié)
```

-----------------------------------------

## Instructions logiques

- Syntaxe : **op{cond}{s} Rd, Rs, Operand**

- op est un mnémonique parmis : **and, eor, tst, teq, orr, mov, bic, mvn**

- cond est un mnémonique conditionnel. (optionnel)

- s indique si le registre cpsr est modifié par l'instruction. (optionnel)

- Rd est le registre de destination

- Rs est le registre source

- Operand est un registre ou une constante

- Exemples

```nasm
        andle r5, r2, #13    ; Stock le résultat de r2 & #13 dans r5 (si <=)
```

----------------------------------------------

## Instructions de multiplications

- Syntaxe 1 : **mul{cond}{s} Rd, Rm, Rs**

- Syntaxe 2 : **mla{cond}{s} Rd, Rm, Rs, Rn**

- cond est un mnémonique conditionnel. (optionnel)

- s indique si le registre cpsr est modifié par l'instruction. (optionnel)

- Rd est le registre de destination

- Rm est le premier opérande.

- Rs est le deuxième opérande.

- Rn est le troisième opérande pour mla.

- Exemples

```nasm
		mul r5, r0, r1      ; Stock dans r5 le résultat de (r0 * r1)
		mla r2, r5, r6, r3  ; Stock dans r2, le résultat de (r5 * r6 + r3)
```

----------------------------------------------

## Instructions de comparaison

- Syntaxe : **op{cond} Rs, Operand**

- op est un mnémonique parmis : **cmp, cmn**

- cond est un mnémonique conditionnel. (optionnel)

- Rs est un registre pour le premier operand

- Operand est un registre ou une constante

- L'instruction cmp soustrait Operand à Rs, et modifie le registre flag

- L'instruction cmn additionne Operand à Rs et modifie le registre flag

- Exemples

```nasm
        cmp r0, #5   ; soustrait 5 à r0, et modifie le registre cpsr
		cmn r4, r6   ; additionne r4 et r6, et modifie le registre cpsr
```

---------------------------------------------

## Instructions d'accés mémoire

- Syntaxe 1 : **op{cond}{b}{t} Rd, [Rs]**

- Syntaxe 2 : **op{cond}{b} Rd, [Rs + off]{!}**

- Syntaxe 3 : **op{cond}{b}{t} Rd, [Rs], off**

- op est un mnémonique parmis : **ldr, str**

- cond est un mnémonique conditionnel. (optionnel)

- b permet de transferer que le byte le moins significatif. (optionnel)

- t n'est pas utilisé en user mode.

- Rd est le registre de destination (pour ldr), ou le registre à transferer (pour str)

- Rs contient l'adresse pour charger ou transferer des données

- offset est un offset appliqué à Rs

- ! indique que l'offset est ajouté à Rs (le registre Rs est alors modifié)

- Exemples

```nasm
        ldrb r0, [r4]         ; Charge dans r0, le byte de l'adresse r4
        str r2, [r1], #42     ; Copie à l'adresse r1, r2, et ajoute 42 à r1
		str r1, [r6 + #75]!   ; Copie à l'adresse r6+75 r1, et ajoute 75 à r1
```

---------------------------------------------

## Instructions d'accés mémoire (multi-registres)

- Syntaxe : **op{cond}mode Rs{!}, reglist{^}**

- op est un mnémonique parmis : **ldm, stm**

- cond est un mnémonique conditionnel (optionnel)

- mode est un mnémonique parmis :

      * **ia** incrémentation de l'adresse après chaque transfert

      * **ib** incrémentation de l'adresse avant chaque transfert

      * **da** décrémentation de l'adresse après chaque transfert

      * **db** décrémentation de l'adresse avant chaque transfert

      * **fd** pile descendante

      * **ed** pile descendante vide

      * **fa** pile ascendante

      * **ea** pile ascendante vide

- Rs contient l'adresse où charger/transferer les registres.

- ! est utilisé pour écrire dans Rs l'adresse finale (optionnel)

- reglist est une liste de registre

- ^ n'est pas utilisé dans le mode user.

- Exemples

```nasm
        stmfd sp!, {r0}    ; Sauvegarde le registre r0, sur la pile.
        ldmfd sp!, {fp,pc} ; Copie dans fp et pc, deux valeurs de la pile.
```

À noter que les instructions push et pop sont un alias de stmfd sp!, reglist et ldmfd sp!, reglist.

-----------------------------------------------------

## Instructions de branchement

- Syntaxe 1 : **op{cond} label**

- Syntaxe 2 : **bx{cond} Rs**

- op est un mnémonique parmis **b, bl**

- cond est un mnémonique conditionnel (optionnel)

- label est l'adresse où effectuer le branchement.

- Rs est le registre contenant l'adresse du saut.

- b (branch) effectue un branchement vers le label

- bl (branch with link) copie l'adresse de la prochaine instruction dans le registre lr avant d'effectuer le branchement.

- bx effectue un branchement vers l'adresse contenue dans Rs, et passe en mode THUMB si le bit 0 du registre Rs est à 1.

- Exemples

```nasm
        bl label ; lr = instruction+4, puis saute vers label.
        b label  ; Effectue un branchement vers label
```

-------------------------------------------------------

## Interruption logicielle

- Syntaxe : **swi{cond} expression**

- cond est un mnémonique conditionnel (optionnel)

- expression est une valeur ignorée par le processeur.


**swi** est l'instruction permettant de générer une interruption logicielle. Elle est utilisée par exemple pour les appels systèmes Linux.
Sur Linux, le numéro de l'appel système est placé dans le registre r7, et les arguments sur la pile.

------------------------------------------------------


## Le mode THUMB

Un petit mot sur le mode THUMB.

Le mode THUMB a été créé afin de diminuer la taille du code. En effet, les instructions ne sont plus codés sur 32 bits comme le mode normal, mais sur 16 bits.

Pour passer du mode normal au mode THUMB, il suffit d'utiliser l'instruction bx. (Je vous renvois au paragraphe concernant les instructions de branchement)

Ce mode peut être très utile afin de supprimer les octets nuls d'un shellcode par exemple, et d'en diminuer la taille.

--------------------------------------------------


## Autres instructions

Il y a certaines instructions dont je n'ai pas parlé dans cet article (PSR transfert, coprocessor data transfert...), je vous renvois au manuel ARM si ça vous intéresse.


# Appels de fonctions

Dans cette partie, je vais tenter de montrer la forme du code Assembleur généré par [GCC](http://fr.wikipedia.org/wiki/GNU_Compiler_Collection).


Tout d'abords, lorsqu'une fonction est appelée, les arguments sont passés dans les registres **r0** à **r3**. Si une fonction possède plus de 4 arguments, alors les autres arguments sont placés sur la pile.

La valeur de retour d'une fonction est quand à elle placée dans le registre **r0**.

Une fonction commence généralement par un **prologue**, et se termine par un **épilogue**. Entre les deux, se trouve le corps de la fonction.

**Le prologue** se charge de sauvegarder le contexte de la fonction appellante, décrit notamment par les registres fp et lr.

**L'épilogue**, lui, s'occupe de recharger le contexte de la fonction appellante, puis retourne vers l'adresse située juste après l'appel.

Analysons un bout de code C, pour voir comment est généré le code assembleur. (sans aucune options d'optimisation)

```c
	#include <stdio.h>

    void foo(const char *s) {
        printf("%s", s);
    }

    int main(void) {

        foo("Hello World");
        return 0;
     }
```

Voici le code assembleur correspondant :

```nasm
	000083cc <foo>:
	83cc:       e92d4800        push    {fp, lr}
	83d0:       e28db004        add     fp, sp, #4
	83d4:       e24dd008        sub     sp, sp, #8
	83d8:       e50b0008        str     r0, [fp, #-8]
	83dc:       e59f3010        ldr     r3, [pc, #16]   ; 83f4 <foo+0x28>
	83e0:       e1a00003        mov     r0, r3
	83e4:       e51b1008        ldr     r1, [fp, #-8]
	83e8:       ebffffc0        bl      82f0 <_init+0x20>
	83ec:       e24bd004        sub     sp, fp, #4
	83f0:       e8bd8800        pop     {fp, pc}
	83f4:       00008488        .word   0x00008488

    000083f8 <main>:
    83f8:       e92d4800        push    {fp, lr}
	83fc:       e28db004        add     fp, sp, #4
	8400:       e59f000c        ldr     r0, [pc, #12]   ; 8414 <main+0x1c>
	8404:       ebfffff0        bl      83cc <foo>
	8408:       e3a03000        mov     r3, #0
	840c:       e1a00003        mov     r0, r3
	8410:       e8bd8800        pop     {fp, pc}
	8414:       0000848c        .word   0x0000848c
```

- En 0x8400, l'adresse de la chaine "Hello World" est placée dans le registre r0

- En 0x8404, on effectue un branchement vers foo, en sauvegardant l'adresse de la prochaine instruction dans lr (link register)

- En 0x83cc et 0x83d0 on a le prologue de la fonction foo. On sauvegarde le registre fp (frame pointer) et le registre lr (link register) sur la pile, puis on place dans fp, l'adresse de sp - 4

- En 0x83d4, on reserve une place sur la pile (8 bytes) pour des variables temporaires.

- En 0x83d8, on sauvegarde le registre r0 dans l'espace mémoire que l'on vient de réserver sur la pile.

- En 0x83dc, on place dans r3, l'adresse de la chaine "%s" (0x8488). Puis en 0x83e0, on place r3 dans r0

- En 0x83e4, on place dans r1 la variable qu'on a sauvegardé sur la pile en 0x83d8.

- En 0x83e8, on appelle la fonction printf. r0 contient l'adresse de la chaine "%s", et r1 contient l'adresse de la chaine "Hello world".

- En 0x83ec et 0x83f0, on a l'epilogue de la fonction foo. On commence par remettre la pile dans le contexte de main, puis on restaure fp, puis pc. En restaurant pc, on revient dans la fonction main. (car le registre lr avait été sauvegardé lors du prologue, et contenait l'adresse situé après l'appel de foo)



# Conclusion

L'article touche à sa fin, et j'espère qu'il a sût vous donner un petit aperçu de l'architecture ARM ainsi que de son jeu d'instructions.

N'étant pas du tout expert en ARM, il se peut que des éléments soient incorrect ou incomplet. N'hésitez pas à me le faire remarquer afin que je puisse les corriger !




##### Références

- ##### [Le manuel ARMv6](http://infocenter.arm.com)

- ##### [Short ARM instructions set](https://repo.t0x0sh.org/Papers/Programming/2007_ARM_instructions_set.pdf)

- ##### [ARM instructions set](https://repo.t0x0sh.org/Papers/Programming/1994_ARMv7_instructions_set.pdf)
