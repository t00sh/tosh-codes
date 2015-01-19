#!/usr/bin/env bash

# Date : 2014-03-22
# Author: Tosh
# 
# Synchronise the local repo with tosh-codes

set -x
set -e

REMOTE_REPO="/usr/share/nginx/www/t0x0sh"
LOCAL_REPO="./repo"

chmod -R 0755 $LOCAL_REPO

rsync -avzh --delete --progress -e ssh $LOCAL_REPO www-data@t0x0sh.org:$REMOTE_REPO/

