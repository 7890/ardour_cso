#!/bin/sh

#create_cso_script_h.sh > cso_script.h

md5="`md5sum cso.lua`"
cat - << __EOF__
#ifndef ardour_cso_script_h
#define ardour_cso_script_h
#include <string>
//cso.lua script, built-in functions, encoded as base64
//$md5
const std::string CSO_SCRIPT = 
__EOF__
echo -n '"'
cat cso.lua | base64 -w0
echo '";'
cat - << __EOF__
#endif
__EOF__
