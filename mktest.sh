#!/bin/bash

# usage: sh mkmodule.sh modulename TestTemplate

MODULENAME="$1"
ORGNAME="$2"
EXT='pde'
## copy everything from MyModule
cp $ORGNAME.$EXT $MODULENAME.$EXT
echo 'Making test file:' "$MODULENAME"."$EXT"
# search and replace in files
sed -i -e 's/'"$ORGNAME"'/'"$MODULENAME"'/g'  $MODULENAME.$EXT
echo "Done"