-- ============================================================================
ardour
{
	["type"] = "CSOSurface"
	,name = "Test Ardour Signal Callbacks"
	,author = "Thomas Brand"
	,description = [[
]]
	,license = "GPLv2"
}

-- ============================================================================
function cso_params () return
{{
	osc_server_port = 9998
	,osc_debug = true
	,timer1_interval_ms = 2500
}}
end

-- ============================================================================
function cso_timer1(interval_ms) 
	print("cso_timer1(" .. interval_ms .. ")")
end

function cso_start()
	print("cso_start()")
end

function cso_shutdown()
	print("cso_shutdown()")
end

-- triggered by /connect
function cso_on_feedback_address_changed(host, port)
	print("cso_on_feedback_address_changed(" .. host .. "," .. port .. ")")
	--update surface_tx for feedback
	surface_osc_uri="osc.udp://" .. host .. ":" .. port
	surface_tx = ARDOUR.LuaOSC.Address (surface_osc_uri)
end

-- triggered by /print/osc/address
function cso_on_print_address_changed(host, port)
	print("cso_on_print_address_changed(" .. host .. "," .. port .. ")")
end

function on_ardour_transport_state_changed()
	print("on_ardour_transport_state_changed()")
end

function on_ardour_record_state_changed()
	print("on_ardour_record_state_changed()")
end

function on_ardour_looped()
	print("on_ardour_looped()")
end

function on_ardour_session_located()
	print("on_ardour_session_located()")
end

function on_ardour_session_exported(name, uri)
	print("on_ardour_session_exported(" .. name .. "," .. uri .. ")")
end

function on_ardour_routes_added()
	print("on_ardour_routes_added()")
end

function on_ardour_route_group_property_changed()
	print("on_ardour_route_group_property_changed()")
end

function on_ardour_dirty_state_changed()
	print("on_ardour_dirty_state_changed()")
end

function on_ardour_state_saved(session_name)
	print("on_ardour_state_saved()")
end

function on_ardour_solo_state_changed(is_soloed)
	--not using tostring to print boolean values (like is_soloed) will crash ardour
	print("on_ardour_solo_state_changed(" .. tostring(is_soloed) .. ")")
end

function on_ardour_config_parameter_changed(param_name)
	print("on_ardour_config_parameter_changed(" .. param_name .. ")")
end

function on_ardour_stripable_selection_changed()
	print("on_ardour_stripable_selection_changed()")
end

-- EOF
