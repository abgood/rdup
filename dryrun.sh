#!/bin/bash
#
# Copyright (c) 2005, 2006 Miek Gieben
# See LICENSE for the license
#

. ./shared.sh

backup_defines
backup_cmd_options $@
backup_create_top $backupdir

declare -a path # catch spacing in the path
while read mode uid gid path
do
        dump=${mode:0:1}        # to add or remove
        mode=${mode:1}          # st_mode bits
        bits=$(($mode & $S_MMASK)) # permission bits
        bits=`printf "%o" $bits` # and back to octal again
        typ=0
        if [[ $(($mode & $S_ISDIR)) == $S_ISDIR ]]; then
                typ=1;
        fi
        if [[ $(($mode & $S_ISLNK)) == $S_ISLNK ]]; then
                typ=2;
        fi
        
        if [[ $dump == "+" ]]; then
                # add
                case $typ in
                        0)      # reg file
                        [ -f "$backupdir/$path" ] && mv "$backupdir/$path" "$backupdir/$path.$suffix"
                        if [[ -z $gzip ]]; then
                                echo "cat $path > $backupdir/$path"
                        else 
                                echo "cat $path | gzip -c > $backupdir/$path"
                        fi
                        ;;
                        1)      # directory
                        echo "[ ! -d $backupdir/$path ] && mkdir -p $backupdir/$path"
                        ;;
                        2)      # link
                        echo "[ -L $backupdir/$path ] && mv $backupdir/$path $backupdir/$path.$suffix"
                        echo "cp -a $path $backupdir/$path"
                        ;;
                esac
                echo "chown $uid:$gid $backupdir/$path"
                echo "chmod $bits $backupdir/$path"
        else
                # remove
                echo "mv $backupdir/$path $backupdir/$path.$suffix"
        fi
done 
