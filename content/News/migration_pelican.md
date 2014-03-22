Title: Migration du site
Date: 2014-03-22
Tags: news
Author: Tosh
Summary: Pelican !


Une petite news pour dire que le site est désormais 100% statique et généré par [Pelican](https://github.com/getpelican/pelican).

## Pourquoi avoir migré ? ###

Tout d'abords, j'en avais un peu marre de **Wordpress**, et je voulais essayer autre chose.
Ensuite, pour moi le plus important reste le contenu et non ce qu'il y a autour.

Le site doit rester rapide et épuré afin de garder une navigation agréable.

Il y a également l'aspect sécurité qui a joué en faveur de **Pelican** : plus de bases SQL, plus de code PHP, rien que du HTML !
**Wordpress** étant aussi la cible de nombreuses attaques, j'ai préféré l'abandonner.

Un autre aspect qui m'a plut chez **Pelican** : celui-ci est entièrement open-source et publié sous licence [GNU affero general public license](http://www.gnu.org/licenses/agpl-3.0.html) et il permet de rendre le code source de son site entièrement public.

Un autre avantage que j'ai trouvé à **Pelican**, c'est le format des fichiers. En effet, le site peut etre entièrement écris grace au langage [Markdown](http://en.wikipedia.org/wiki/Markdown), qui a l'avantage d'etre lisible avec un simple éditeur.
C'est un langage simple, disposant d'assez peu de fonctionnalités, mais qui est largement suffisant pour écrire des articles sur ce blog.

Enfin, le site a vocation dans un futur proche de tourner sur un serveur **Raspberry Pi**, l'absence de PHP/MySQL devrait permettre d'obtenir des performances satisfaisantes sur ce type de machine, et la migration sera un jeu d'enfant !

