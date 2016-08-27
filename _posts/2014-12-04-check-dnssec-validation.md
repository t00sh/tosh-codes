---
title: Tester la validation DNSSEC de son resolveur DNS
date: 2014-12-04
tags: dns,dnssec
author: Tosh
layout: post
---

Comment vérifer que le résolveur que vous utilisez vérifie bien les signatures [DNSSEC](http://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) des domaines que vous consultez ?

Rien de plus simple ! il suffit d'utiliser l'utilitaire [dig](http://en.wikipedia.org/wiki/Dig_%28command%29) sur une zone ayant une signature [DNSSEC](http://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) erronée :

```
$ dig sigok.verteiltesysteme.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10465
```

```
$ dig sigfail.verteiltesysteme.net | grep status
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 24646
```

Si vous avez bien un SERVFAIL dans le deuxième cas, c'est que votre résolveur vérifie bien les signature DNSSEC !
