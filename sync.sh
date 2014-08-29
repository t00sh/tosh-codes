#!/usr/bin/env bash

# Date : 2014-03-22
# Author: Tosh
# 
# Synchronise the local repo with tosh-codes


AGENT_NAME="ssh-agent"
REMOTE_REPO="/usr/share/nginx/www"

if [ -f $HOME/.ssh/$AGENT_NAME ]
then
    . $HOME/.ssh/$AGENT_NAME
    pelican content
    cd output
    chmod -R 0755 ./
    rsync -e ssh -pazvc --delete-after ./* www-data@t0x0sh.org:$REMOTE_REPO
fi

