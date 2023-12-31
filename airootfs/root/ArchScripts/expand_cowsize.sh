#!/usr/bin/env bash

# This script will expand the available space in the live ISO,
# in case you absolutely need to install something heavier than 256 MB,
# like a web browser (for emergency use).

BASEDIR=$(readlink -f ${0%/*})
PRINTERFILE="printer.sh"
PRINTERPATH="${BASEDIR}/${PRINTERFILE}"
SIZE=4G

source $PRINTERPATH

print_message ">> Expanding Live ISO space to $SIZE ... <<"
mount -o remount,size=$SIZE /run/archiso/cowspace
