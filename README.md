# ardour_cso
Control Surface Object (CSO) - a scriptable OSC control surface module for Ardour

```
OSC messages understood by CSO
==============================

"s": lua string
("/eval",            "s",    osc_eval)

"sss": path, types, lua function name
("/map/add",         "sss",  osc_map_add)

"ss": path, types
("/map/remove",      "ss",   osc_map_remove)

(no arguments)
("/map/clear",       "",     osc_map_clear)

(no arguments)
("/map/dump",        "",     osc_map_dump)

(no arguments): set feedback address to host and port from requester
"si": host, port
("/connect",         NULL,   osc_connect)

turn on/off CSO debug output
accepts i,T,F
("/debug",           NULL,   osc_debug)

turn on/off print() to stderr from lua
accepts i,T,F
("/print/stderr",    NULL,   osc_print)

turn on/off print() to osc address from lua
accepts i,T,F
("/print/osc",       NULL,   osc_print_osc)

set destination osc host to send print() as string
("/print/osc/address", "si", osc_print_osc_address)

the above pathes can't be re-defined in lua.
the rest of the osc path namespace can be freely used and i.e. bound to lua functions.

NULL, NULL: match all paths, all types
(NULL,               NULL,   osc_catchall)

examples:

set surface address (i.e. oscdump in another terminal for testing)
  /connect si localhost 9001

add lua function
  /eval s "function foo(x) print('hello from lua ' .. x) end"

bind osc message /bar i to foo(x):
  /map/add sss "/bar" "i" "foo"

call foo
  /bar i 42

get custom feedback (can be put to a bound function, also see /connect)
  /eval s "sendme('/pos', 'i', Session:transport_frame())"

default CSO OSC port is 9999
default CSO surface address is localhost:9000
```
