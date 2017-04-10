#!/bin/bash

#//tb/1704

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#lame
echo "# ardour_cso"
echo "Control Surface Object (CSO) - a scriptable OSC control surface module for Ardour"
echo ""
echo '```'
echo "OSC messages understood by CSO"
echo "=============================="
echo ""
cat "$DIR"/cso.cc \
	| grep -A1000 '^//__SOSC' \
	| grep -B1000 "^//__EOSC" \
	| grep -v '^//__SOSC' \
	| grep -v '^//__EOSC' \
	| sed 's/^\tCSO_ADD_OSC_HANDLER//g' \
	| sed 's/^\t//g' \
	| sed 's/;//g' \
	| sed 's/\/\/ //g'
echo '```'
