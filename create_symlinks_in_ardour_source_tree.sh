#!/bin/bash

#//tb/1704

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CSO_HOME="$DIR"

echo "this script will create the necessary symbolic links in the ardour source tree in order to build the CSO control surface module."
echo "nothing will be done unless confirmed. use ctrl+c to abort."
echo "enter full path to ardour source tree:"
read ARDOUR_HOME

if [ ! -d "$ARDOUR_HOME" ]
then
	echo "directory $ARDOUR_HOME does not exist"
	exit 1
fi

#check if the provided directory could be ardour home
if [ ! -d "$ARDOUR_HOME"/libs/surfaces ]
then
	echo "directory $ARDOUR_HOME is probably not the ardour home directory"
	exit 1
fi

#check if current directory could be cso home
if [ ! -d "$CSO_HOME"/libs/surfaces/cso ]
then
	echo "directory $CSO_HOME is probably not the cso home directory"
	exit 1
fi

tmpfile="`mktemp`"
(
echo "rm -f \"$ARDOUR_HOME/libs/surfaces/wscript\""
echo "rm -rf \"$ARDOUR_HOME/libs/surfaces/cso\""
echo "rm -f \"$ARDOUR_HOME/gtk2_ardour/ardev_common.sh.in\""
echo "ln -s \"$CSO_HOME/libs/surfaces/cso\" \"$ARDOUR_HOME/libs/surfaces/\""
echo "ln -s \"$CSO_HOME/libs/surfaces/wscript\" \"$ARDOUR_HOME/libs/surfaces/\""
echo "ln -s \"$CSO_HOME/gtk2_ardour/ardev_common.sh.in\" \"$ARDOUR_HOME/gtk2_ardour/\""
echo "ln -s \"$CSO_HOME/scripts/cso/\" \"$ARDOUR_HOME/scripts/\""
) > "$tmpfile"

echo ""
echo "#commands to be executed:"
cat "$tmpfile"
echo ""
echo "continue? (ctrl+c to abort now)"

read a

sh "$tmpfile"
rm -f "$tmpfile"

echo "done. now rebuild ardour: cd \"$ARDOUR_HOME\" && ./waf build"
echo "good luck!"

#EOF
