#!/bin/bash

current=$(pwd)
scripting='sourcemod/addons/sourcemod/scripting'

if [ "$1" != "" ]; then
    cp $1 $scripting
    cd $scripting
    ./compile.sh $1
    rm $1
    mv compiled/*.smx $current/compiled
    cd $current
else
    echo "Usage: compile.sh <filename.sp>"
fi

