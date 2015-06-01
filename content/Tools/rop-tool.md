Title: rop-tool 2.3
Date: 2015-06-01
Tags: tools,rop,exploit
Author: Tosh
Summary: A tool to help you writing binary exploits


Bonjour à tous !

Voici un petit article concernant [rop-tool](https://github.com/t00sh/rop-tool) v2.3, un outil que je développe sur mon temps libre permettant de faciliter l'écriture d'exploits applicatif, mais pas que...

## **Aperçu**

[rop-tool](https://github.com/t00sh/rop-tool) est un ensemble d'outil regroupé en un, permettant de réaliser des tâches courantes lorsque l'on écrit un exploit applicatif, comme la recherche de gadgets, le désassemblage, le patching, ou la recherche dans un fichier.

[rop-tool](https://github.com/t00sh/rop-tool) est un logiciel libre, publié sous licence [GPLv3](http://www.gnu.org/licenses/gpl-3.0.txt), et utilisant en interne [capstone-engine](http://capstone-engine.org/), pour tout ce qui est désassemblage.

J'ai essayé de développer [rop-tool](https://github.com/t00sh/rop-tool) de façon modulaire, afin de pouvoir rajouter des fonctionnalités rapidement et facilement. Il y a d'une part l'API, qui est un ensemble de fonctions permettant par exemple de manipuler les fichiers binaires de façon transparente concernant le type de fichier, faire de l'affichage, désassembler des portions de code, etc...

Cette API pourrait même permettre de créer de nouveaux outils, sans aucun rapport avec [rop-tool](https://github.com/t00sh/rop-tool).

D'autre part, il y a les outils intégrés à [rop-tool](https://github.com/t00sh/rop-tool), qui utilisent cette API présents sous forme de commandes.

[rop-tool](https://github.com/t00sh/rop-tool) est constitué d'un ensemble de commandes internes, chacune permettant de réaliser une tâche précise.

#### Liste des commandes :

1. **gadget**       -> permet de rechercher des gadgets dans un binaire, dans l'optique de faire du Return Oriented Programming.
* **info**         -> affiche quelques infos sur le binaire (sections, segments, symboles, point d'entrée...).
* **disassemble**  -> permet de désassembler en partie le binaire.
* **patch**        -> cette commande sert à patcher un binaire, chose courante en reversing ou écriture d'exploits. (pour enlever un ptrace ou un fork...)
* **heap**         -> cette fonctionnalité est utile lorsqu'on cherche à exploiter une vulnérabilité basé sur le heap (heap overflow, double free, use after free...). Cette commande permet de visualiser la structure interne du heap (partitionné en "chunks") à chaque appel de fonction du style malloc, realloc, calloc ou free. (disponible uniquement sur GNU/Linux)
* **search**       -> permet de rechercher des informations dans le binaire (chaine, entiers...)
* **help**         -> affiche l'aide globale, ou à propos d'une commande particulière.
* **version**      -> affiche la version.

#### Architectures

[rop-tool](https://github.com/t00sh/rop-tool) supporte les architectures x86, x86-64, arm et arm64. D'autres architectures seront supportées à l'avenir.

#### Formats

[rop-tool](https://github.com/t00sh/rop-tool) permet de manipuler les fichiers ELF, PE et MachO. Certaines fonctionnalités ne sont pas encore implémentées sur PE et MachO.

--------------------------

## **Fonctionnalités**

### Recherche de gadgets

On peut rechercher simplement des gadgets grâce à la commande :

```
rop-tool gadget ./binaire
```

Ici, certains filtres sont appliqués sur les gadgets (pour les architectures x86 et x86-64), mais on peut choisir de ne pas les appliquer :

```
rop-tool gadget ./binaire -F
```

Il arrive souvent que certains caractères posent problème lorsqu'il sont insérés dans un payload (par exemple les espaces, les sauts de ligne ou le caractère '\0').

On peut spécifier quels caractères ne doivent pas apparaître dans l'addresse (par exemple en filtrant le saut de ligne et le nul byte) :

```
rop-tool gadget ./binaire -b "\x0a\x00"
```

Pour les architectures x86 et x86-64, on peut afficher les gadgets avec la syntaxe AT&T :

```
rop-tool gadget ./binaire -f att
```

Par défault, rop-tool colore l'affichage, mais des fois les couleurs peuvent poser problème, ou on veut simplement les désactiver :

```
rop-tool gadget ./binaire -n
```

Parfois, le format de fichier est corrompu, ou inconnu, mais on connait par exemple l'architecture du binaire cible, dans ce cas, on peut ouvrir le binaire en mode "raw" (ici, avec l'architecture arm64) :

```
rop-tool gadget ./binaire -A arm64
```

### Patch

On peut facilement patcher un binaire avec la commande (ici, on patch l'offset 0x100 avec 5 NOP) :

```
rop-tool patch ./binaire -o 0x100 -b "\x90\x90\x90\x90\x90"
```

Plutôt qu'un offset, on peut utiliser une addresse :

```
rop-tool patch ./binaire -a 0x08048a02 -b "\x90\x90\x90\x90\x90"
```

Au lieu d'écraser le fichier, on peut sauvegarder la version patché dans un autre fichier :

```
rop-tool patch ./binaire -a 0x08048a02 -b "\x90\x90\x90\x90\x90" -O autre_fichier
```

Si le format n'est pas reconnu, on peut ouvrir le fichier en mode "RAW" :

```
rop-tool patch ./binaire -o 0x205 -b "\x90\x90\x90\x90\x90" -r
```

### Info

On peut afficher les infos générales sur un binaire avec la commande :

```
rop-tool info ./binaire
```

Afficher toutes les infos :

```
rop-tool info ./binaire -a
```

Afficher les segments :

```
rop-tool info ./binaire -l
```

Afficher les sections :

```
rop-tool info ./binaire -s
```

Afficher les symboles :

```
rop-tool info ./binaire -S
```


### Visualitation du HEAP

On peut "tracer" les fonctions utilisant le heap, avec la commande :

```
rop-tool heap ./binaire
```

Par défault, la bibliothèque permettant de tracer ces fonctions est dumpé dans /tmp/, mais on peut changer le répertoire avec :

```
rop-tool heap ./binaire -t ./mon_tmp/
```

### Désassemblage

On peut désassembler le binaire à partir de l'entry point avec :

```
rop-tool dis ./binaire
```

On peut changer l'addresse où commencer le désassemblage :

```
rop-tool dis ./binaire -a 0x08048921
```

Ou spécifier un offset :

```
rop-tool dis ./binaire -o 0x208
```

On peut ne désassembler qu'un nombre d'octets précis (ici 100 octets) :

```
rop-tool dis ./binaire -l 100
```

On peut également désassembler un symbole, si le binaire n'a pas été stripé :

```
rop-tool dis ./binaire -s main
```

Si le format n'est pas supporté, on peut ouvrir le fichier en mode "RAW" (ici, avec l'architecture x86-64) :

```
rop-tool dis ./binaire -A x86-64
```

Et finalement, il est possible de changer la syntaxe pour les architecture x86 et x86-64 :

```
rop-tool dis ./binaire -f att
```

### Recherche

On peut chercher toutes les chaines du binaire :

```
rop-tool search ./binaire -a
```

On peut aussi chercher un octet :

```
rop-tool search ./binaire -b 0x41
```

On peut préciser des caractères à exclure dans l'addresse de la chaine (ici le saut de ligne et le nul byte) :

```
rop-tool search ./binaire -a -B "\x0a\x00"
```

On peut rechercher un double word (entier de 32 bits) :

```
rop-tool search ./binaire -d 0x41424344
```

Ou un entier 16 bits :

```
rop-tool search ./binaire -w 0x1337
```

Ou encore un entier 64 bits :

```
rop-tool search ./binaire -q 0xdeadbeefdeadbeef
```

Il est possible d'ouvrir le fichier en mode "RAW" si le format n'est pas supporté :

```
rop-tool search ./binaire -a -r
```

Une fonctionnalité pratique lorsque l'on écrit des exploits intégrant du ROP, c'est de pouvoir chercher une chaine non contigue en mémoire :

```
rop-tool search ./binaire -S "/bin/sh\x00"
```

On peut aussi chercher une chaine contigue :

```
rop-tool search ./binaire -s "/bin/sh\x00"
```

---------------------------------

## **Screenshots**

```
rop-tool gadget /bin/ls
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen1.png)

```
rop-tool search /bin/ls -a
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen2.png)

```
rop-tool search /bin/ls -s "/bin/sh\x00"
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen3.png)

```
rop-tool search /bin/ls -w 0x90
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen4.png)

```
rop-tool heap ./a.out
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen5.png)


```
rop-tool dis ./bin  # Many formats
```

![ScreenShot](https://t0x0sh.org/repo/rop-tool/screens/screen6.png)


## **Contribuer**

Si l'envie vous en dit, il est possible de contribuer à cet outil, en proposant des patchs si vous savez programmer en C, en soumettant des bugs, en améliorant la documentation, en proposant de nouvelles fonctionnalités ou simplement en utilisant cet outil :) .

## **Liens**

1. [rop-tool git](https://github.com/t00sh/rop-tool)
* [rop-tool releases](https://t0x0sh.org/rop-tool/releases/)
* [capstone-engine](http://capstone-engine.org/)


