#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Tosh'
SITENAME = "<Tosh'codes>"
SITEURL = 'http://tosh-codes.tuxfamily.org'

TIMEZONE = 'Europe/Paris'

DEFAULT_LANG = 'fr'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = 'feeds/all.atom.xml'
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None

# Blogroll
LINKS = (('ZadYree', 'http://z4d.tuxfamily.org/blog/'),
         ('W4kfu', 'http://blog.w4kfu.com/'),
         ('RootBSD', 'http://www.r00ted.com/'),
         ('RootMe', 'http://www.root-me.org/'),
         ('LSE', 'http://blog.lse.epita.fr/'),
         ('kmkz', 'http://kmkz-web-blog.blogspot.fr/'),
         ('HackBBS', 'http://hackbbs.org/index.php'),
         ('Bases-Hacking', 'http://bases-hacking.org/'),
)

# Social widget
SOCIAL = (('Twitter', 'https://twitter.com/define__tosh__'),
          ('Github', 'https://github.com/t00sh'),
)

DEFAULT_PAGINATION = 5

STATIC_PATHS = ['images']

# Uncomment following line if you want document-relative URLs when developing
RELATIVE_URLS = False

THEME = "themes/pelican-simplegrey"
