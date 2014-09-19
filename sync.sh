#!/usr/bin/env bash

# Date : 2014-03-22
# Author: Tosh
# 
# Synchronise the local repo with tosh-codes

set -x
set -e

REMOTE_REPO="/usr/share/nginx/www"
LOCAL_REPO="./output"

pelican content
cp -R repo $LOCAL_REPO/
chmod -R 0755 $LOCAL_REPO

rsync -rvap --delete --progress -e ssh $LOCAL_REPO/* www-data@10.8.0.1:$REMOTE_REPO/

