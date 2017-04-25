-- null.lua
-- ============================================================================
ardour
{
	["type"] = "CSOSurface"
	,name = "NULL CSO Script"
	,author = "Thomas Brand"
	,description = [[Loads all available CSO Lua libraries then does nothing]]
	,license = "GPLv2"
}
-- using default cso_params() (from cso.lua)
-- ============================================================================
function cso_params () return
{{
-- 	osc_server_port = 9999
-- 	,osc_debug = true
	timer1_interval_ms = 0
	-- load all currently available libraries for testing
	,loadlibs={'touchosc.lua', 'ardour_actions.lua', 'json.lua', 'xmlSimple.lua'}
}}
end

-- ============================================================================
function cso_start()
	print("cso_start()")
	-- oscsend localhost 9999 /evalb s "`cat test/xmlSimpleTest.lua | base64 -w0`"
	cso_map_add("/evalb", "s", "cso_eval_base64");
	-- don't flood stderr with base64 when receiving evalb
	cso_debug(false)
end

-- ============================================================================
-- function cso_shutdown()
-- 	print("cso_shutdown()")
-- end

-- EOF
