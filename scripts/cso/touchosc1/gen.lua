-- created with touchosc_to_lua.sh Don Apr 13 22:54:03 CEST 2017
-- it's not recommended to edit this file manually

function tosc_build_surface(model, host, port)
tosc_set_surface_address(model, host, port)
tosc_add_layout_data(model, 'UEsDBBQACAgIAM61jUoAAAAAAAAAAAAAAAAJAAAAaW5kZXgueG1sxZlrc6JIFIb/isX32UBz0a4KmXI24o4Tk4hykS9b3Lw2klK84K/fhgaUmVyARf2Qoiia9OM5p9/zdnP//eChxs5db+b+SqSYv2iq4a5s35mvpiKljKRvLer7wz0yQ38bnI3jqYbnO65I4fH+eu6uAjOIn8zw3dHHt4h6uA9M682cuo2V6eGhTlea9weiSDU2toncCX45mi6+CZK5H+5t/PLaR8k7lgQXVhcuTAYGFpAR1TiIlCBQjRC/gMfv8aXFUY2ZSAF8a/vIX4vU2nWoRhC+4X+ATMtFM3znHvAcahcFhva8M7pKhDE/4hEMft0y7eV07W9XjkgF662Lf9Q2QPMVfjwx0caNwO4Ssj8QPZVzJBiM9d7a0H+KMSIQmHNGnokRo8s54sdxIPBv2w1GRz5+8q8/mRSAsf/pIQf9BiPcBMXQ+EWUMnsqEgymSTi4VgwCWk2St+haBiWuT3f96dyedMQ5CQ3debO8wXkYACBxaF4tDoTFs9gei9OyJPXB0TeiAZC2GIiyqGQkLf4mJEcsC6HTFnM5ujaLhaXJ0PZhzEDKVOCIujCEAfBfq4uyhP3R33CkduDgI3VJUErIC0E7kiUEwTkczxdmG3XgqxJHuV4umnCxTEUuZak+1sZke3BjpaVE0hiJS5xGmpQSXa6UAn86RW6umEh/+FqCT+0qBmH5K6/0tC9lHOlKvzqJ7amLpEy486TwV8sJthA7Oy0MBjZvQzHW5KUOmJntBaeumDqFlOZq5SHBPU4MiCFgrjC44pL3WqukSHBr6DM6iYtQGWpav84R/QV8K5es4jo3UOTOZbQX8Oy59grN4j1BkYZDWh3WmUBsLCJ7rYa40BObHS05mjCCqE+U7aqdww9NmUkDZVB/93rOzCmT2KAmSS0nlAgjelHVfo1wGto6ej8NHU/AeEBqjo3BWiXlqoJqdw+MvU/DI7C3ocgSdSJJPSJTNlG/9hfwPy9ZW6HzYFGkCoI9DWoEG3sS7eAF6I7SvShL5J1jiEK06E/ALDMI3HU4K7g7/rrxxlFiYhAuZ+5LCPrkcV974kDSZWBVqNdV/VBsDMXntoYlBB2baX2o8LU3msPLIClyeH6UcDOfkOzW+u3MQwlVuS5gFcJ+Gi2imaxAWkqzTGeGHblOUcjQMtvJtt6FK3CIdjm4fT5uNFc2bgoj/1BQ/T4hfM5KjeOrwskXWJnHLKHfUocFy3I9Ddvc06Jdv2XO8gk4mJM0vnjPlpeGLl9API6njCYroULkfoU1R24MDrsxCCaWBpdGqiJCM3GmueNutuQOscquOT18T/PYBDmSJniX5L1I9R/bwtlfFjEg/M+IGRL0DU0KnW4PjfX0TJP4HUC8KkN2aQxfLmAoGnQ+8V3yOePd7xrTkt81cqdnQqIpINkd0cUb2EDvLS1WDX9K8pulffxVo8pebmZ78s7RexMn+mwyyI7xSXhZjtC22MKw1hwWNZZf8sVMo2STlAYwRfrM4QZzzy1JsXHx3M6msN2lM7/EV8+s3FWBqT2jGjJ7qtw78iXv4T9QSwcIMG6I/4IEAAD4GwAAUEsBAhQAFAAICAgAzrWNSjBuiP+CBAAA+BsAAAkAAAAAAAAAAAAAAAAAAAAAAGluZGV4LnhtbFBLBQYAAAAAAQABADcAAAC5BAAAAAA=');
-- tabs
tosc_add_tab(model, "tab1", "/tab1")
tosc_add_tab(model, "tab2", "/tab2")
-- tab1
tosc_add_widget(model, {["name"]="bF9jbG9ja19tb2Rl", ["x"]=66, ["y"]=10, ["w"]=184, ["h"]=20, ["color"]="red", ["type"]="labelh", ["text"]="VGltZWNvZGU=", ["size"]=14, ["background"]="true", ["outline"]=false, ["n"]="l_clock_mode", ["t"]="Timecode", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/l_clock_mode"}) 
tosc_add_widget(model, {["name"]="bmV4dF9tYXJrZXI=", ["x"]=261, ["y"]=10, ["w"]=51, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="next_marker", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/next_marker"}) 
tosc_add_widget(model, {["name"]="cHJldl9tYXJrZXI=", ["x"]=6, ["y"]=10, ["w"]=51, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="prev_marker", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/prev_marker"}) 
tosc_add_widget(model, {["name"]="ZW5jb2Rlcg==", ["x"]=17, ["y"]=148, ["w"]=287, ["h"]=287, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="encoder", ["n"]="encoder", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/encoder"}) 
tosc_add_widget(model, {["name"]="ZmFzdF9yZXdpbmQ=", ["x"]=6, ["y"]=220, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="fast_rewind", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/fast_rewind"}) 
tosc_add_widget(model, {["name"]="ZmFzdF9mb3J3YXJk", ["x"]=240, ["y"]=220, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="fast_forward", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/fast_forward"}) 
tosc_add_widget(model, {["name"]="Z290b19lbmQ=", ["x"]=240, ["y"]=285, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="goto_end", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/goto_end"}) 
tosc_add_widget(model, {["name"]="Z290b19zdGFydA==", ["x"]=6, ["y"]=285, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="goto_start", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/goto_start"}) 
tosc_add_widget(model, {["name"]="bGFiZWwy", ["x"]=7, ["y"]=64, ["w"]=111, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="Uk9MTC9TVE9Q", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label2", ["t"]="ROLL/STOP", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label2"}) 
tosc_add_widget(model, {["name"]="bGFiZWwz", ["x"]=192, ["y"]=64, ["w"]=55, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="TE9PUA==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label3", ["t"]="LOOP", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label3"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0", ["x"]=131, ["y"]=64, ["w"]=55, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="UkVD", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label4", ["t"]="REC", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label4"}) 
tosc_add_widget(model, {["name"]="cm9sbA==", ["x"]=7, ["y"]=87, ["w"]=110, ["h"]=50, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=true, ["n"]="roll", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/roll"}) 
tosc_add_widget(model, {["name"]="cHJldl9tb2Rl", ["x"]=6, ["y"]=350, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="prev_mode", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/prev_mode"}) 
tosc_add_widget(model, {["name"]="bmV4dF9tb2Rl", ["x"]=240, ["y"]=350, ["w"]=71, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="next_mode", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/next_mode"}) 
tosc_add_widget(model, {["name"]="cmVj", ["x"]=134, ["y"]=87, ["w"]=50, ["h"]=50, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=true, ["n"]="rec", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/rec"}) 
tosc_add_widget(model, {["name"]="bG9vcA==", ["x"]=197, ["y"]=87, ["w"]=50, ["h"]=50, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=true, ["n"]="loop", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/loop"}) 
tosc_add_widget(model, {["name"]="YWRkX21hcmtlcg==", ["x"]=261, ["y"]=87, ["w"]=51, ["h"]=51, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="add_marker", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/add_marker"}) 
tosc_add_widget(model, {["name"]="bF9wcmV2", ["x"]=9, ["y"]=350, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="PA==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="l_prev", ["t"]="&lt;", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/l_prev"}) 
tosc_add_widget(model, {["name"]="bF9uZXh0", ["x"]=266, ["y"]=350, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="Pg==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="l_next", ["t"]="&gt;", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/l_next"}) 
tosc_add_widget(model, {["name"]="bGFiZWwz", ["x"]=258, ["y"]=87, ["w"]=55, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="QURE", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label3", ["t"]="ADD", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label3"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0", ["x"]=253, ["y"]=64, ["w"]=67, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="TUFSS0VS", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label4", ["t"]="MARKER", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label4"}) 
tosc_add_widget(model, {["name"]="bF9lbmNvZGVyX21vZGU=", ["x"]=103, ["y"]=231, ["w"]=111, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="UExBWUhFQUQ=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="l_encoder_mode", ["t"]="PLAYHEAD", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/l_encoder_mode"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0Ng==", ["x"]=110, ["y"]=277, ["w"]=46, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="TUlOVVM=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label46", ["t"]="MINUS", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label46"}) 
tosc_add_widget(model, {["name"]="bWludXM=", ["x"]=105, ["y"]=252, ["w"]=53, ["h"]=80, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="minus", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/minus"}) 
tosc_add_widget(model, {["name"]="cGx1cw==", ["x"]=163, ["y"]=252, ["w"]=53, ["h"]=80, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="push", ["local_off"]=false, ["n"]="plus", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/plus"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0Nw==", ["x"]=166, ["y"]=281, ["w"]=46, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="Kw==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label47", ["t"]="+", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label47"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0OA==", ["x"]=106, ["y"]=281, ["w"]=52, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="LQ==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label48", ["t"]="-", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label48"}) 
tosc_add_widget(model, {["name"]="YmF0dGVyeTI=", ["x"]=239, ["y"]=414, ["w"]=80, ["h"]=25, ["color"]="red", ["type"]="batteryh", ["size"]=14, ["background"]="true", ["outline"]=true, ["n"]="battery2", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/battery2"}) 
tosc_add_widget(model, {["name"]="bGFiZWw1", ["x"]=4, ["y"]=285, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="fDw=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label5", ["t"]="|&lt;", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label5"}) 
tosc_add_widget(model, {["name"]="bGFiZWw2", ["x"]=269, ["y"]=285, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="Pnw=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label6", ["t"]="&gt;|", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label6"}) 
tosc_add_widget(model, {["name"]="bGFiZWw3", ["x"]=5, ["y"]=220, ["w"]=67, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="UkVXSU5E", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label7", ["t"]="REWIND", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label7"}) 
tosc_add_widget(model, {["name"]="bGFiZWwxOQ==", ["x"]=9, ["y"]=10, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="PA==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label19", ["t"]="&lt;", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label19"}) 
tosc_add_widget(model, {["name"]="bGFiZWwyMA==", ["x"]=266, ["y"]=10, ["w"]=41, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="Pg==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label20", ["t"]="&gt;", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label20"}) 
tosc_add_widget(model, {["name"]="bGFiZWwyMQ==", ["x"]=3, ["y"]=367, ["w"]=77, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="TU9ERQ==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label21", ["t"]="MODE", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label21"}) 
tosc_add_widget(model, {["name"]="bGFiZWwyMg==", ["x"]=238, ["y"]=367, ["w"]=77, ["h"]=20, ["color"]="red", ["type"]="labelh", ["text"]="TU9ERQ==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label22", ["t"]="MODE", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label22"}) 
tosc_add_widget(model, {["name"]="bGFiZWwyMw==", ["x"]=3, ["y"]=304, ["w"]=77, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="U1RBUlQ=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label23", ["t"]="START", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label23"}) 
tosc_add_widget(model, {["name"]="bGFiZWwyNA==", ["x"]=245, ["y"]=304, ["w"]=77, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="RU5E", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label24", ["t"]="END", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label24"}) 
tosc_add_widget(model, {["name"]="bGFiZWwzMg==", ["x"]=-3, ["y"]=239, ["w"]=77, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="LSA4LjA=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label32", ["t"]="- 8.0", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label32"}) 
tosc_add_widget(model, {["name"]="bGFiZWwzMw==", ["x"]=249, ["y"]=220, ["w"]=56, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="RkZXRA==", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label33", ["t"]="FFWD", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label33"}) 
tosc_add_widget(model, {["name"]="bGFiZWwzNA==", ["x"]=238, ["y"]=239, ["w"]=77, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="KyA4LjA=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label34", ["t"]="+ 8.0", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/label34"}) 
tosc_add_widget(model, {["name"]="Y2xvY2tfbW9kZQ==", ["x"]=67, ["y"]=27, ["w"]=184, ["h"]=31, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="toggle", ["local_off"]=true, ["n"]="clock_mode", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/clock_mode"}) 
tosc_add_widget(model, {["name"]="bF9jbG9jaw==", ["x"]=72, ["y"]=27, ["w"]=172, ["h"]=31, ["color"]="red", ["type"]="labelh", ["text"]="MDA6MDA6MDA6MDA=", ["size"]=26, ["background"]="false", ["outline"]=false, ["n"]="l_clock", ["t"]="00:00:00:00", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/l_clock"}) 
tosc_add_widget(model, {["name"]="ZF9oZWFydGJlYXQ=", ["x"]=2, ["y"]=422, ["w"]=15, ["h"]=15, ["color"]="red", ["scalef"]=0.0, ["scalet"]=1.0, ["type"]="led", ["n"]="d_heartbeat", ["t"]="", ["tab"]="tab1", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab1/d_heartbeat"}) 

-- tab2
tosc_add_widget(model, {["name"]="bGFiZWw0", ["x"]=165, ["y"]=321, ["w"]=101, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="QXJkb3VyIFRpbWU=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label4", ["t"]="Ardour Time", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/label4"}) 
tosc_add_widget(model, {["name"]="bF9hcmRvdXJfdGltZQ==", ["x"]=172, ["y"]=341, ["w"]=83, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="bi9h", ["size"]=14, ["background"]="true", ["outline"]=false, ["n"]="l_ardour_time", ["t"]="n/a", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/l_ardour_time"}) 
tosc_add_widget(model, {["name"]="dGltZTM=", ["x"]=65, ["y"]=341, ["w"]=80, ["h"]=25, ["color"]="red", ["type"]="timeh", ["size"]=14, ["background"]="true", ["outline"]=false, ["seconds"]="true", ["n"]="time3", ["t"]="", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/time3"}) 
tosc_add_widget(model, {["name"]="bGFiZWw0OQ==", ["x"]=55, ["y"]=321, ["w"]=101, ["h"]=25, ["color"]="red", ["type"]="labelh", ["text"]="RGV2aWNlIFRpbWU=", ["size"]=14, ["background"]="false", ["outline"]=false, ["n"]="label49", ["t"]="Device Time", ["tab"]="tab2", ["v"]=0, ["z"]=10, ["visible"]=true, ["path"]="/tab2/label49"}) 

end
-- function tosc_build_surface()
-- EOF