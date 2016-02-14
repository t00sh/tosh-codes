#!/usr/bin/env bash

# Date : 2014-03-22
# Author: Tosh
#
# Synchronise the local repo with tosh-codes

set -x
set -e

REMOTE_REPO="/home/t0x0sh/www/t0x0sh"
LOCAL_REPO="./output"

pelican content -s pelicanconf.py
chmod -R 0755 $LOCAL_REPO

rsync -a --progress -e ssh $LOCAL_REPO/* t0x0sh@t0x0sh.org:$REMOTE_REPO/