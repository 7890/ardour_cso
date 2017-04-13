-- ============================================================================
ardour
{
	["type"] = "CSOSurface"
	,name = "CSO Test Script for TouchOSC"
	,author = "Thomas Brand"
	,description = [[
Glue for TouchOSC layout 'basic.touchosc' to work with Ardour control surface module 'CSO'.

This layout includes two tabs, with a led, label, push and toggle on each, plus a rotary and an encoder.
It serves to test the lua representation of these widgets provided by the layout-independent touchosc.lua library.

In order to run this script the CSO surface module must be available in your build and activated.
This can be done in Ardour menu Edit/Preferences/Control Surfaces.
]]
	,license = "GPLv2"
}

-- ============================================================================
function cso_params() return
{{
	osc_server_port = 9998
	,osc_debug = true
	-- setting inverval to 0 disables timer callback
	,timer1_interval_ms = 2222
	-- relative path to <ardour scripts dir>/cso/
	,loadlibs = {'touchosc.lua', 'touchosc0/gen.lua'}
}}
end

-- ============================================================================
-- ============================================================================

-- global variable holding the control surface interface description
-- as a tree of nested lists containing key/value properties and functions.
-- this table is populated by tosc_build_surface() (see cso_start()).
m={}
-- explore: m:dump()
-- or parts: m.tab1:dump()
-- mymodel.mytab.mybutton:dump()
-- send to Ardour CSO OSC server port:
-- /eval s "m:dump()"

-- dump() prints to stderr in the terminal where Ardour was started.
-- to copy / redirect lua print() to another terminal / host via OSC message /print s:
-- activate osc printing:
-- /print/osc i 1
-- set osc printing host:
-- /print/osc/address si localhost 3333

-- ============================================================================
function cso_start()
	print("cso_start()")

	--defined in in gen.lua
--	tosc_build_surface(m, "localhost", 9993)
	tosc_build_surface(m, "10.10.10.51", 9000)
	--m{} was filled via tosc_add_tab(), tosc_add_widget() in tosc_build_surface() 

	--see below
	attach_event_handlers_to_model()

	tosc_create_osc_mappings_from_model(m)

	-- additional mapping
	cso_map_add("/evalb", "s", "cso_eval_base64");

	-- set initial values
	-- switch to tab1
	m.tab1:activate()
	-- make sure tab1 is updated, call like surface would switch to it
	m.tab1:event()
end

-- example callback functions
-- ============================================================================
function on_ardour_transport_state_changed() print(Session:transport_rolling()) end
function cso_timer1(interval_ms) print("timer callback every " .. interval_ms .. " milliseconds") end

-- ============================================================================
function mylog(self, f)
	print(ARDOUR.LuaAPI:monotonic_time() .. ": got " .. self:type() .. " message " .. self:path() .. " " .. f)
end

-- ============================================================================
function attach_event_handlers_to_model()
	-- examples on how to bind :event() to widgets and control widgets on the surface

	--tabs
	function m.tab1:event()
		mylog(self,0)
		--update ..
	end

	function m.tab2:event()
		mylog(self,0)
		--update ..
	end

	--tab 1 widgets
	function m.tab1.push1:event(f)
		mylog(self,f)
		if f==1 then m.tab1.led1:set(.5)
		else m.tab1.led1:set(1) end
	end

	function m.tab1.toggle1:event(f)
		mylog(self,f)
		if f==1 then m.tab1.led1:set_color('red')
		else m.tab1.led1:set_color('blue') end
	end

	function m.tab1.fader1:event(f)
		mylog(self,f)
		m.tab1.rotary1.set(f)
	end

	function m.tab1.rotary1:event(f)
		mylog(self,f)
		m.tab1.fader1:set(f)
	end

	--tab2 widgets
	function m.tab2.push1:event(f)
		mylog(self,f)
		if f==1 then m.tab2.label1:hide()
		else m.tab2.label1:show() end
	end

	function m.tab2.toggle1:event(f)
		mylog(self,f)
		if f==1 then
			m.tab2.label1:set_position(1,1)
			m.tab2.label1:set('text me')
		else m.tab2.label1:reset() end
	end

	function m.tab2.fader1:event(f)
		mylog(self,f)
	end

	function m.tab2.encoder1:event(f)
		mylog(self,f)
	end
end

-- ============================================================================
function cso_shutdown()
	print("cso_shutdown()")
end

--EOF
