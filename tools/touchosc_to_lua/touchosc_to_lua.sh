#!/bin/bash

#generate lua code from touchosc file
#./touchosc_to_lua.sh mylayout.touchosc > gen.lua

#original touchosc file is zipped xml file with base64 encoded strings

#output of this shell script:

#wrap in function function tosc_build_surface(model, host, port):

# tosc_add_layout_data=xx
# tosc_set_surface_address(model,host,port)
# tosc_add_tab(model,name,path)
# ...
# tosc_add_widget(model,{table})
# ...


#//tb/1704

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

checkAvail()
{
	which "$1" >/dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]
	then
		echo "tool \"$1\" not found. please install" >&2
		echo "<error>tool \"$1\" not found. please install</error>"
		exit 1
	fi
}

for tool in {xmlstarlet,zcat,base64,mktemp}; \
	do checkAvail "$tool"; done

if [ $# -ne 1 ]
then
	echo "need touchosc file"
	exit 1
fi

original_touchosc_file="$1"

if [ ! -r "$original_touchosc_file" ]
then
	echo "file not found: $original_touchosc_file"
	exit 1
fi

#must be in current directory
touchosc_base64_to_plain="$DIR"/"touchosc_base64_to_plain.xsl"

tmpfile=`mktemp`
#unzip to plain text
zcat "$original_touchosc_file" | xmlstarlet fo > "$tmpfile"
ret=${PIPESTATUS[0]}
if [ "$ret" -ne 0 ]
then
	echo "there was an error. maybe the file is not a touchosc file (?)."
	exit 1
fi

#################
#start lua output
echo "-- created with touchosc_to_lua.sh `date`"
echo "-- it's not recommended to edit this file manually"
echo ""

echo "function tosc_build_surface(model, host, port)"
echo "tosc_set_surface_address(model, host, port)"

#allowing to retrieve the touchosc layout corresponding to this generated output
echo -n "tosc_add_layout_data(model, '"
cat "$original_touchosc_file" | base64 -w 0
echo "');"

#function calls to build model
echo "-- tabs"
xmlstarlet tr "$touchosc_base64_to_plain" "$tmpfile" \
	| xmlstarlet sel -t -m "//tabpage" \
	-o 'tosc_add_tab(model, "' -v @n \
	-o '", "' --if "@custom_osc_plain" -v "@custom_osc_plain" --else -v "concat('/', @n)" -b -o '")' -n

#use all available @attributes, don't use quotes if is number
xmlstarlet tr "$touchosc_base64_to_plain" "$tmpfile" \
	| xmlstarlet sel -t -m "//tabpage" \
	-o '-- ' -v @n -n \
	-m "control" \
	-o 'tosc_add_widget(model, {' \
	-m "@*" \
	--if "name(.)!='x' and name(.)!='y' and name(.)!='w' and name(.)!='h' and name(.)!='size' and name(.)!='scalef' and name(.)!='scalet' and name(.)!='outline' and name(.)!='local_off'" \
		-v "concat('[\"', name(.), '\"]=\"', ., '\"')" \
	--else \
		-v "concat('[\"', name(.), '\"]=', .)" \
	-b \
	-o ', ' \
	-b -o '["tab"]="' -v "../@n" -o '", ["v"]=0, ["z"]=10, ["visible"]=true, ' \
	-o '["path"]="' --if "@custom_osc_plain" -v "@custom_osc_plain" --else -v "concat('/', ../@n, '/', @n)" -b \
	-o '"}) ' -n \
	-b -n

echo "end"
echo "-- function tosc_build_surface()"
echo "-- EOF"

rm -f "$tmpfile"

exit

####
#EOF
