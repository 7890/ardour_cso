#!/bin/bash

#//tb/1704/07

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CSO_HOME="$DIR"

echo "this script will create the necessary symbolic links in the ardour source tree in order to build and use the CSO control surface module."
echo "in the ardour source tree, two files will be altered:"
echo "   libs/surfaces/wscript"
echo "   gtk2_ardour/ardev_common.sh.in"
echo "nothing will be done unless confirmed. use ctrl+c to abort."
echo "enter absolute path to ardour source tree:"
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
echo "#link cso source directory to ardour source tree libs/surfaces"
echo "rm -rf \"$ARDOUR_HOME/libs/surfaces/cso\""
echo "ln -s \"$CSO_HOME/libs/surfaces/cso\" \"$ARDOUR_HOME/libs/surfaces/\""

echo "#patch libs/surfaces/wscript if necessary to build cso module"
echo "(cat \"$ARDOUR_HOME/libs/surfaces/wscript\"|grep bld|grep cso >/dev/null) || patch -p1 \"$ARDOUR_HOME/libs/surfaces/wscript\" < \"$CSO_HOME/libs/surfaces/wscript.diff\""

echo "#add cso to ARDOUR_SURFACES_PATH in ardev_common.sh.in"
echo "(cat \"$ARDOUR_HOME/gtk2_ardour/ardev_common.sh.in\"|grep ARDOUR_SURFACES_PATH|grep cso >/dev/null) || cat \"$CSO_HOME/gtk2_ardour/ardev_common.sh.in.add\" >> \"$ARDOUR_HOME/gtk2_ardour/ardev_common.sh.in\""

echo "#add hack for GTK / ubuntu in ardev_common.sh.in"
echo "(cat \"$ARDOUR_HOME/gtk2_ardour/ardev_common.sh.in\"|grep LIBOVERLAY_SCROLLBAR >/dev/null) || echo \"export LIBOVERLAY_SCROLLBAR=0\" >> \"$ARDOUR_HOME/gtk2_ardour/ardev_common.sh.in\""

echo "#link the cso scripts directory to ardour source tree scripts"
echo "ln -s \"$CSO_HOME/scripts/cso/\" \"$ARDOUR_HOME/scripts/\" 2>/dev/null"
) > "$tmpfile"

echo "#####################################################"
echo "#commands to be executed:"
cat "$tmpfile"
echo "#####################################################"
echo ""
echo "continue? (ctrl+c to abort now)"

read a

sh "$tmpfile"
rm -f "$tmpfile"

echo "==========="
cur="`pwd`"
cd "$ARDOUR_HOME"
git diff libs/surfaces/wscript
git diff gtk2_ardour/ardev_common.sh.in
ls -l libs/surfaces/cso
ls -l scripts/cso
echo "==========="
cd "$cur"

echo "done"
echo "now rebuild ardour from scratch."
echo "on success, the cso module should be visible in the ardour preferences dialog."
echo "good luck!"
echo ""

echo "#!/bin/sh" > "$CSO_HOME/remove_cso.sh"
(
echo ""
echo "rm -f \"$ARDOUR_HOME/libs/surfaces/cso\""
echo "rm -f \"$ARDOUR_HOME/scripts/cso\""
echo "cd \"$ARDOUR_HOME\""
echo "git checkout libs/surfaces/wscript"
echo "git checkout gtk2_ardour/ardev_common.sh.in"
echo "echo done."
) >> "$CSO_HOME/remove_cso.sh"
chmod 755 "$CSO_HOME/remove_cso.sh"

echo "to remove all cso related from ardour source tree use this script:"
echo "$CSO_HOME/remove_cso.sh"

#EOF
