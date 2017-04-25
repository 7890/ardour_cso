-- cso.lua
-- 
--  ====    ====    ====  
-- ==  ==  ==  ==  ==  == 
-- ==      ==      ==  == 
-- ==       ====   ==  == 
-- ==          ==  ==  == 
-- ==  ==  ==  ==  ==  == 
--  ====    ====    ====  
-- Control Surface Object 

-- CSO script glue, loaded by libs/surfaces/cso.cc
-- providing some datastructures and functions for surface integration scripts

-- this file must not be changed by users of CSO.
-- it builds a fixed relation to cso.cc.

-- ============================================================================
-- when changing this file (cso.lua), run this command to create the header file:
-- ./create_cso_script_h.sh > cso_script.h
-- ============================================================================

-- cso_script.h will contain this script (cso.lua) as base64 encoded std::string named
-- CSO_SCRIPT

-- //tb/1704

-- ============================================================================
ardour
{
	["type"] = "CSOSurface"
	,name = "Control Surface Object (CSO) Script"
	,author = "Thomas Brand"
	,description = [[
CSO is all OSC. And Lua. And a lot of Ardour. Its aimed at making it simple to integrate any OSC surface to control Ardour:
-Defining the Ardour OSC API dynamically using the Lua scripting environment.
-Triggering Lua functions upon an Ardour event or when a control surface / OSC program requests a reply.
-Events and requests can be mapped to Lua functions which in turn can access many Ardour methods and send (back) OSC.
-Feedback is always sent as OSC and can be freely shaped to match the usecase.
-In order to run this script the CSO surface module must be available in your build and activated.
This can be done in Ardour menu Edit/Preferences/Control Surfaces.
]]
	,license = "GPLv2"
}

-- surface integration script can override this function
-- (for instance to use alternative osc server port)
-- ============================================================================
function cso_params () return
{{
	osc_server_port = 9999
	,osc_debug = true
	,timer1_interval_ms = 250
}}
end

-- global variables
cso_api_version = 0
osc_server_port = 0

-- uri and tx can/will be reconfigured in cso_start() of surface integration script
-- to match the osc server port in use
self_osc_uri = "osc.udp://localhost:9999"
self_tx = ARDOUR.LuaOSC.Address (self_osc_uri)

-- uri and tx can be reconfigured using /connect
surface_osc_uri="osc.udp://localhost:9000"
surface_tx = ARDOUR.LuaOSC.Address (surface_osc_uri)

-- ============================================================================
function cso_print_global_env() for n in pairs(_G) do print(n) end print ('----') end
function llength(t) local c = 0 for k, v in pairs(t) do c = c + 1 end return c end

-- send an OSC message to the configured feedback host (~surface)
-- types that normally are arg-less should have arg anyways
-- ============================================================================
function sendme(path, types, ...) surface_tx:send (path, types, ...) end

-- wrapper functions to call "self" using OSC for IPC. this will trigger the generic CSO methods in cso.cc
-- ============================================================================
function cso_eval(luatext) self_tx:send ("/eval", "s", luatext) end
function cso_map_add(path, types, lua_function) self_tx:send ("/map/add", "sss", path, types, lua_function) end
function cso_map_remove(path, types) self_tx:send ("/map/remove", "ss", path, types) end
function cso_map_clear() self_tx:send ("/map/clear", "") end
function cso_map_dump() self_tx:send ("/map/dump", "") end
function cso_set_feedback_address(host, port) self_tx:send ("/connect", "si", host, port) end
function cso_debug(do_debug) if do_debug then self_tx:send ("/debug", "T", true) else self_tx:send ("/debug", "F", false) end end

-- ============================================================================
function cso_init(_cso_api_version, _osc_server_port) 
	print("cso_init()")
	cso_api_version=_cso_api_version
	osc_server_port=_osc_server_port
	--re-configure
	self_osc_uri = "osc.udp://localhost:" .. osc_server_port
	self_tx = ARDOUR.LuaOSC.Address (self_osc_uri)
end
function cso_timer1(interval_ms) end
function cso_start() end
function cso_shutdown() end

-- triggered by /connect
-- ============================================================================
function cso_on_feedback_address_changed(host, port)
	print("cso_on_feedback_address_changed(): " .. host .. ":" .. port)
	--update surface_tx for feedback
	surface_osc_uri="osc.udp://" .. host .. ":" .. port
	surface_tx = ARDOUR.LuaOSC.Address (surface_osc_uri)
end

-- triggered by /print/osc/address
-- ============================================================================
function cso_on_print_address_changed(host, port)
	print("cso_on_print_address_changed(): " .. host .. ":" .. port)
end

-- ============================================================================
-- ============================================================================
-- call back functions that are called upon a registered ardour signal.
-- the function name cannot be freely defined. obviously only existing functions will be called.
-- there is no error if a function for a signal is not defined.
-- /!\ the callback list is not complete

-- ============================================================================
function on_ardour_transport_state_changed() end
function on_ardour_record_state_changed() end
function on_ardour_looped() end
-- updating the clock on every locate makes other "goto_xx" code simpler
function on_ardour_session_located() end
function on_ardour_session_exported(path, name) end
function on_ardour_routes_added() end
--///
function on_ardour_route_group_property_changed() end
function on_ardour_dirty_state_changed() end
function on_ardour_state_saved(session_name) end
function on_ardour_solo_state_changed(is_soloed) end
function on_ardour_config_parameter_changed(param_name) end
function on_ardour_stripable_selection_changed() end

-- "built-in" helper methods
-- ============================================================================
-- ============================================================================
function rec_going_on()
	return ARDOUR.Session.RecordState.Enabled == Session:record_status() or Session:actively_recording()
end

-- ============================================================================
function route_by_id(rid) return Session:route_by_id( PBD.ID(tostring(rid)) ) end

-- ============================================================================
-- "leading zero" formatter
function lz2(number) return string.format("%02d", number) end
function lz3(number) return string.format("%03d", number) end
function lz4(number) return string.format("%04d", number) end
-- http://lua-users.org/wiki/SimpleRound, round towards 0
function round0(num) if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end end
function ibool(is_true) if is_true then return 1 else return 0 end end

-- ============================================================================
function cso_timecode_clock_string(position)
	--hh, mm, ss, ff = ARDOUR.LuaAPI.sample_to_timecode (Timecode.TimecodeFormat.TC25, samplerate, playhead)
	--using session framerate, fps
	local hh, mm, ss, ff = Session:sample_to_timecode_lua (position)
	-- timecode hours minutes seconds frames
	return lz2(hh) .. ":" .. lz2(mm) .. ":" .. lz2(ss) .. ":" .. lz2(ff)
end

-- ============================================================================
function cso_bbt_clock_string(position)
	-- bbt bars beats ticks
	local tmap=Session:tempo_map()
	local bbtime=tmap:bbt_at_frame(position)
	return lz3(bbtime.bars) .. "|" .. lz2(bbtime.beats) .. "|" .. lz4(bbtime.ticks)
end

-- ============================================================================
function cso_hms_clock_string(position)
	local hh, mm, ss, ff = Session:sample_to_timecode_lua (position)
	-- hms hours minutes seconds milliseconds
	local ms = 1000 * ff / Session:timecode_frames_per_second()
	return lz2(hh) .. ":" .. lz2(mm) .. ":" .. lz2(ss) .. "." .. lz3(round0(ms))
end

-- load and evaluate lua code as base64 string
-- ============================================================================
function cso_eval_base64(base64_string) load(cso_base64_dec(base64_string))() end

-- https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
-- print a table recursively in a tree-like structure
-- ============================================================================
function print_r ( t )
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end
-- print_r

--https://gist.github.com/haggen/2fd643ea9a261fea2094
-- ============================================================================
local charset = {}
-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

--this is not really random (?)
--caller can append ARDOUR.LuaAPI:monotonic_time()
function string.random(length)
--	math.randomseed(os.time())
	math.randomseed(ARDOUR.LuaAPI:monotonic_time())
	if length > 0 then
		return string.random(length - 1) .. charset[math.random(1, #charset)]
	else
		return ""
	end
end

-- http://stackoverflow.com/questions/1426954/split-string-in-lua
-- ============================================================================
function string.split(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

-- EOF
