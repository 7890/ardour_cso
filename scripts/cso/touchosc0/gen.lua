-- created with touchosc_to_lua.sh Don Apr 13 20:18:50 CEST 2017
-- it's not recommended to edit this file manually

function tosc_build_surface(model, host, port)
tosc_set_surface_address(model, host, port)
tosc_add_layout_data(model, 'UEsDBBQACAgIABUpjUoAAAAAAAAAAAAAAAAJAAAAaW5kZXgueG1s7ZVNb5tAEIb/Ctp7a4PBHxKQS2u3lXpo1SYpl2iBARMvO9ayONi/vhN2axG1sUp6qpTTatiZeR/mQxtedbVwDqCaCmXE3LdT5oDMMK9kGbHv39ZvluwqDgU/YqsHfgFzaswhYuSPqgKpue5vtmSdkEzB4lDzdM9LcCSvyTXfrKvPX6KIOU3GBRQU/CjXG9pqx2FGwQqFjUk31zsT00XMWzLnSI4L5jyQRe5bc2QoUEVMQX4ptz7uKaN4dIrDidX5XXBdJTcPXS+4sIK+EfQCoxg8VbR5eQpiSxZ0epimqU5gUqQ825UKW5lHTKsWqHKtFpWk64KLBi5hZR+uT/zd+yd1mK96LN9Q+cG4OuzbhmgF0s0dFsVfMOSblUy8Tpz74brTIYi7mr2IRGNZChjHktTrXXL70bTJ822b5qZPSzMZc38cR8FzUFQTBc0eZUNfeNqgaDWRVJJmX0N+Rsto5EENPlzoXb2a/rj9FJzrtpj1vN5sZuq28Hre/hwDrFBzdTy8lFgiMQokt1/zOPyHiV3eP25x+brFr1v8v2yxAkGP0+Eftzi5Ce5T76vI7m3/grnZYs+1g+zaSXbHAffPLajntm9i3t74J1BLBwi3G2rZyQEAAKoHAABQSwECFAAUAAgICAAVKY1Ktxtq2ckBAACqBwAACQAAAAAAAAAAAAAAAAAAAAAAaW5kZXgueG1sUEsFBgAAAAABAAEANwAAAAACAAAAAA==');
-- tabs
tosc_add_tab(model, "tab1", "/tab1")
tosc_add_tab(model, "tab2", "/tab2")
-- tab1
tosc_add_widget(model, {["name"]="bGVkMQ==", ["x"]=28, ["y"]=17, ["w"]=20, ["h"]=20, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="led", ["n"]="led1", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/led1"}) 
tosc_add_widget(model, {["name"]="bGFiZWwx", ["x"]=78, ["y"]=14, ["w"]=225, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="bGFiZWwx", ["size"]=14, ["background"]="true", ["outline"]=false, ["n"]="label1", ["t"]="label1", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label1"}) 
tosc_add_widget(model, {["name"]="cHVzaDE=", ["x"]=28, ["y"]=69, ["w"]=45, ["h"]=45, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="push1", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/push1"}) 
tosc_add_widget(model, {["name"]="dG9nZ2xlMQ==", ["x"]=110, ["y"]=69, ["w"]=193, ["h"]=45, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=false, ["n"]="toggle1", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/toggle1"}) 
tosc_add_widget(model, {["name"]="ZmFkZXIx", ["x"]=24, ["y"]=146, ["w"]=280, ["h"]=64, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="faderh", ["response"]="absolute", ["inverted"]="false", ["centered"]="false", ["n"]="fader1", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/fader1"}) 
tosc_add_widget(model, {["name"]="cm90YXJ5MQ==", ["x"]=73, ["y"]=233, ["w"]=172, ["h"]=172, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="rotaryv", ["response"]="absolute", ["inverted"]="false", ["centered"]="false", ["norollover"]="true", ["n"]="rotary1", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/rotary1"}) 

-- tab2
tosc_add_widget(model, {["name"]="bGVkMQ==", ["x"]=28, ["y"]=17, ["w"]=20, ["h"]=20, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="led", ["n"]="led1", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/led1"}) 
tosc_add_widget(model, {["name"]="bGFiZWwx", ["x"]=78, ["y"]=14, ["w"]=225, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="bGFiZWwx", ["size"]=14, ["background"]="true", ["outline"]=false, ["n"]="label1", ["t"]="label1", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/label1"}) 
tosc_add_widget(model, {["name"]="cHVzaDE=", ["x"]=28, ["y"]=69, ["w"]=45, ["h"]=45, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="push1", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/push1"}) 
tosc_add_widget(model, {["name"]="dG9nZ2xlMQ==", ["x"]=110, ["y"]=69, ["w"]=193, ["h"]=45, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=false, ["n"]="toggle1", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/toggle1"}) 
tosc_add_widget(model, {["name"]="ZmFkZXIx", ["x"]=24, ["y"]=146, ["w"]=280, ["h"]=64, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="faderh", ["response"]="relative", ["inverted"]="false", ["centered"]="false", ["n"]="fader1", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/fader1"}) 
tosc_add_widget(model, {["name"]="ZW5jb2RlcjE=", ["x"]=56, ["y"]=221, ["w"]=201, ["h"]=201, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="encoder", ["n"]="encoder1", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/encoder1"}) 

end
-- function tosc_build_surface()
-- EOF
