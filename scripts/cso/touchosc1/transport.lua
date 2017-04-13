-- ============================================================================
ardour
{
	["type"] = "CSOSurface"
	,name = "CSO Script for TouchOSC"
	,author = "Thomas Brand"
	,description = [[
Glue for TouchOSC Layout 'transport.touchosc' to work with Ardour control surface module 'CSO'. 

Controlling the Ardour transport.

In order to run this script the CSO surface module must be available in your build and activated.
This can be done in Ardour menu Edit/Preferences/Control Surfaces.
]]
	,license = "GPLv2"
}

--osc device running the touchosc layout
local surface_host="10.10.10.51"
local surface_port=9000

-- ============================================================================
function cso_params() return
{{
	--set touchosc to send to this port (and ip address of the host where ardour runs on)
	osc_server_port = 9998
	,osc_debug = true
	,timer1_interval_ms = 250
	,loadlibs = {'touchosc.lua', 'touchosc1/gen.lua'}
}}
end

-- local status variables
-- ============================================================================
-- ============================================================================

-- toggling 0 / 1
local heartbeat_toggle=0
local interval_counter=0
-- if interval set to 250 ms: every x * 250 ms
local send_heartbeat_every_nth_interval=7
-- used to set roll status correctly after fast forward / rewind
local transport_was_rolling=false
-- how many frames to step per encoder impluse (if in Playhead mode)
local step_frame_count=Session:nominal_frame_rate()
-- the context in which encoder impulses should be interpreted
local encoder_mode=1
local encoder_modes={ "PLAYHEAD", "ZOOM" }
-- clock display styles
local clock_mode=1
local clock_modes={ "Timecode", "Bars:Beats", "Minutes:Seconds", "Samples" }

-- global variable
-- model containing the touchosc layout widgets populated in tosc_build_surface()
m={}

-- helper methods for this layout
-- ============================================================================
function tosc_send_heartbeat()
	if m:active_tab() == "tab1" then
		if heartbeat_toggle == 1 then heartbeat_toggle = 0 
		elseif heartbeat_toggle == 0 then heartbeat_toggle = 1
		end
		m.tab1.d_heartbeat:set(heartbeat_toggle)
	elseif m:active_tab() == "tab2" then
		--https://www.lua.org/pil/22.1.html date format
		m.tab2.l_ardour_time:set(os.date("%H:%M:%S"))
	end
end

-- ============================================================================
function tosc_update_clock()
	-- send clock update (no checks if reasonable)
	local position = Session:transport_frame()
	local str = "" .. position
	-- timecode hours:minutes:seconds:frames
	if clock_mode == 1 then str = cso_timecode_clock_string(position)
	-- bbt bars|beats|ticks
	elseif clock_mode == 2 then str = cso_bbt_clock_string(position)
	-- hms hours:minutes:seconds.milliseconds
	elseif clock_mode == 3 then str = cso_hms_clock_string(position)
	--elseif clock_mode == 4 then (samples)
	end
	m.tab1.l_clock:set(str)
end

-- ============================================================================
function tosc_next_clock_mode()
	clock_mode = clock_mode + 1
	if clock_mode > llength(clock_modes) then clock_mode = 1 end
	m.tab1.l_clock_mode:set(clock_modes[clock_mode])
	tosc_update_clock()
end

-- ============================================================================
function tosc_prev_encoder_mode()
	encoder_mode = encoder_mode - 1
	if encoder_mode < 1 then encoder_mode = llength(encoder_modes) end
	m.tab1.l_encoder_mode:set(encoder_modes[encoder_mode])
end

-- ============================================================================
function tosc_next_encoder_mode()
	encoder_mode = encoder_mode + 1
	if encoder_mode > llength(encoder_modes) then encoder_mode = 1 end
	m.tab1.l_encoder_mode:set(encoder_modes[encoder_mode])
end

-- ============================================================================
-- ============================================================================
-- callback functions that are called upon the emission of a registered ardour signal.
-- see cso.lua for currently supported signals.
-- all these callback functions follow a naming scheme of on_ardour_xxx

-- ============================================================================
function on_ardour_transport_state_changed()
	-- don't send update to touchosc if not on tab1
	if m:active_tab() ~= "tab1" then return end
	-- set roll indication
	m.tab1.roll:set(Session:transport_rolling())
	-- set loop indication
	m.tab1.loop:set(Session:get_play_loop())
	tosc_update_clock()
end

-- ============================================================================
function on_ardour_record_state_changed()
	if m:active_tab() ~= "tab1" then return end
	-- set rec indication
	m.tab1.rec:set(rec_going_on())
end

-- ============================================================================
function on_ardour_looped()
	print("LOOP")
end

-- updating the clock on every locate makes other "goto_xx" code simpler
-- ============================================================================
function on_ardour_session_located()
	if m:active_tab() ~= "tab1" then return end
	tosc_update_clock()
end

-- ============================================================================
function on_ardour_config_parameter_changed(param)
	print("PARAM CHANGE: " .. param)
end

-- ============================================================================
function on_ardour_session_exported(path, name)
	print("SESSION EXPORTED: " .. path .. " " .. name)
end

-- ============================================================================
function on_ardour_routes_added()
	print("ROUTES ADDED ")
end

-- ============================================================================
function on_ardour_solo_state_changed(is_soloed)
	print("SOLO STATE CHANGED TO: " .. is_soloed)
end

-- ============================================================================
-- ============================================================================
-- callback functions that are called upon an incoming OSC message for which a mapping was found.
-- the names of such functions can be freely defined 
-- (as long as they don't clash with an existing / built-in function).
-- the function name and arguments are used to add a mapping (see /map/add)
function attach_event_handlers_to_model()
-- ============================================================================
function m.tab1:event()
	m.props.active_tab="tab1"

	self.roll:set(Session:transport_rolling())
	self.loop:set(Session:get_play_loop())
	self.rec:set(rec_going_on())
	tosc_update_clock()
end

-- ============================================================================
function m.tab2:event()
	m.props.active_tab="tab2"
	-- update tab2
end

-- ============================================================================
function m.tab1.roll:event(f)
	CSO:toggle_roll()
end

-- ============================================================================
function m.tab1.rec:event(f)
	CSO:toggle_rec()
end

-- ============================================================================
function m.tab1.loop:event(f)
	if rec_going_on() then return end
	CSO:toggle_loop()
end

-- ============================================================================
function m.tab1.add_marker:event(f)
	-- ignore button release
	if f == 0 then return end
	CSO:access_action('Common/add-location-from-playhead')
--	local loc = Session:locations() -- all marker locations
end

-- ============================================================================
function m.tab1.prev_marker:event(f)
	if f == 0 then return end
	if rec_going_on() then return end
	CSO:prev_marker()
end

-- ============================================================================
function m.tab1.next_marker:event(f)
	if f == 0 then return end
	if rec_going_on() then return end
	CSO:next_marker()
end

-- ============================================================================
function m.tab1.goto_start:event(f)
	if f == 0 then return end
	if rec_going_on() then return end
	Session:goto_start(Session:transport_rolling())
end

-- ============================================================================
function m.tab1.goto_end:event(f)
	if f == 0 then return end
	if rec_going_on() then return end
	Session:goto_end()
end

-- ============================================================================
function m.tab1.fast_rewind:event(f)
	if rec_going_on() then return end
	if f == 0 then
		if transport_was_rolling then
			Session:request_transport_speed(1.0, true)
		else
			Session:request_stop()
		end
	else
		transport_was_rolling=Session:transport_rolling()
		Session:request_transport_speed(-8.0, true)
		--this shouldn't be necessary
		--(transport rolling only works for first fast_rewind / fast_forward) ?
		if not(Session:transport_frame() == 0) then
			m.tab1.roll:on()
		end
	end
end

-- ============================================================================
function m.tab1.fast_forward:event(f)
	if rec_going_on() then return end
	if f == 0 then
		if transport_was_rolling then
			Session:request_transport_speed(1.0, true)
		else
			Session:request_stop()
		end
	else
		--if playhead is at position 0 and there are no regions yet requesting speed 8 won't work
		--(if session start and end are both at zero, a transport rule says if current_frame = session_end ignore speed requests)
		--it that case moving playhead 1 sample forward first
		transport_was_rolling=Session:transport_rolling()
		local position = Session:transport_frame()
		if not(transport_was_rolling) and position == 0 then Session:request_locate(1, false) end
		Session:request_transport_speed(8.0, true)
		--this shouldn't be necessary
		m.tab1.roll:on()
	end
end

-- ============================================================================
function m.tab1.encoder:event(f)
	-- encoder can control several things depending on context/mode:
	-- -playhead locate
	-- -zoom level
	-- -...

	if encoder_mode == 1 and not rec_going_on() then
		local rolling=Session:transport_rolling()
		local current_frame=Session:transport_frame()
		local target_fame
		if f == 0 then
			-- minus
			target_frame=current_frame - step_frame_count
			if(target_frame < 0) then target_frame = 0 end
		else
			-- plus
			target_frame=current_frame + step_frame_count
		end
		Session:request_locate(target_frame, rolling)
	elseif encoder_mode == 2 then
		if f == 0 then
			CSO:temporal_zoom_out()
		else
			CSO:temporal_zoom_in()
		end
	-- elseif
		-- dummy
	end
end

-- ============================================================================
function m.tab1.minus:event(f)
	if f == 0 then return end
	m.tab1.encoder(0.0)
end

-- ============================================================================
function m.tab1.plus:event(f)
	if f == 0 then return end
	m.tab1.encoder(1.0)
end

-- ============================================================================
function m.tab1.clock_mode:event(f)
	if f == 0 then return end
	tosc_next_clock_mode()
end

-- ============================================================================
function m.tab1.prev_mode:event(f)
	if f == 0 then return end
	tosc_prev_encoder_mode()
end

-- ============================================================================
function m.tab1.next_mode:event(f)
	if f == 0 then return end
	tosc_next_encoder_mode()
end
end
-- attach_event_handlers_to_model()

-- ============================================================================
function cso_timer1(interval_ms)
--	print(",")
	if m:active_tab() == "tab1" then
		if Session:transport_rolling() then
			tosc_update_clock()
		end
	end
	interval_counter=interval_counter + 1
	if interval_counter > send_heartbeat_every_nth_interval then
		--heartbeat will differentiate tabs
		tosc_send_heartbeat()		
		interval_counter=1
	end
end

-- ============================================================================
function cso_start()
	print("cso_start()")
	tosc_build_surface(m, surface_host, surface_port)
	attach_event_handlers_to_model()
	tosc_create_osc_mappings_from_model(m)

	cso_map_add("/evalb", "s", "cso_eval_base64");
	m.tab1:activate()
	m.tab1:event()
end

-- ============================================================================
function cso_shutdown()
	print("cso_shutdown()")
end

--EOF
