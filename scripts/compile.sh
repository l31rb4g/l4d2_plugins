#!/bin/bash

current=$(pwd)
scripting='sourcemod/addons/sourcemod/scripting'

if [ "$1" != "" ]; then
    if [ -f "$1" ]; then
        filename=$(basename "$1")
        cp $1 $scripting
        cd $scripting
        ./compile.sh $filename
        rm $filename
        mv compiled/*.smx $current/compiled
    else
        echo "File not found: $1"
    fi
else
    echo "Usage: compile.sh <filename.sp>"
fi

