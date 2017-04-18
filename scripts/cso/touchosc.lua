-- touchosc.lua
--
--  ====    ====    ====  
-- ==  ==  ==  ==  ==  == 
-- ==      ==      ==  == 
-- ==       ====   ==  == 
-- ==          ==  ==  == 
-- ==  ==  ==  ==  ==  == 
--  ====    ====    ====  
-- Control Surface Object 

-- this script can be loaded into CSO to get some convenience functions
-- for TouchOSC layouts (tested with TouchOSC 1.9.8).

-- /!\ incomplete widget support

-- see https://hexler.net/software/touchosc for more information on TouchOSC
-- look for the touchosc-editor-x.y.z-platform.zip

-- the author of this script is not related to hexler.net.
-- this is a user contribution.

-- tosc is a shortcut for touchosc

-- a nested table is holding the pseudo representation of touchosc surface
-- in a nutshell: model.tab1.mybutton:on() -> will turn button on (on the surface)
-- device2.t2.push:dump() -> shows all properties and functions for this widget
-- ============================================================================
-- ============================================================================
-- ============================================================================

-- creates osc mappings from global model{} "object"
-- ============================================================================
function tosc_create_osc_mappings_from_model(model)
	print("create " .. llength(model) .. " tab mappings")
	for tabname, tab in pairs(model) do
		-- expecting a table
		if not(type(tab) == 'table') or not tab.props then goto _skip end
		-- add mapping for tabs
		cso_map_add(tab.props.path, "", tab.props.random);
		str="function " .. tab.props.random .. "() m." .. tab.props.n .. ":event() end"
		load(str)()

		-- /!\ (atm just push, toggle, encoder, rotaryh, rotaryv, faderh, faderv)
		-- add mappings for widgets
		for key, widget in pairs(model[tabname]) do
			--print("TYPE " .. type(widget))
			if type(widget) == 'table'
			and widget.props
			and (widget:type() == 'push' 
				or widget:type() == 'toggle'
				or widget:type() == 'encoder'
				or widget:type() == 'rotaryh'
				or widget:type() == 'rotaryv'
				or widget:type() == 'faderh'
				or widget:type() == 'faderv'
			)
			then
				-- add mapping for widget
				cso_map_add(widget.props.path, "f", widget.props.random);
				str="function " .. widget.props.random .. "(f) m." 
					.. widget.props.tab .. "." .. widget.props.n .. ":event(f) end"
				load(str)()
			end
		end
		::_skip::
	end
end
-- tosc_create_osc_mappings_from_model()

-- generic functions to be attached to model{}
-- ============================================================================
-- ============================================================================
function tosc_activate_tab(self)
	self:send('')
	local r=self:root()
	r.props.active_tab=self.props.n
end

-- /!\ too many messages!?
-- set all widgets in this tab to default values (as initially created)
-- ============================================================================
function tosc_reset_tab(self)
	for key, widget in pairs(self) do
--		print("TYPE " .. type(widget))
		if type(widget) == 'table'
		then
			widget:reset()
		end
	end
end

-- resetting widget to default values
-- ============================================================================
function tosc_reset_widget(self)
	local tx=self:root()
	tx:send (self:path() .. "/visible", "i", 1 )
	tx:send (self:path() .. "/position/x", "i", self.props.x )
	tx:send (self:path() .. "/position/y", "i", self.props.y )
	tx:send (self:path() .. "/size/w", "i", self.props.w )
	tx:send (self:path() .. "/size/h", "i", self.props.h )
	tx:send (self:path() .. "/color", "s", self.props.color )
	local p=self.props
	if p.t then
		tx:send (self:path(), "s", p.t )
	end
	if p.scalef then
		tx:send (self:path(), "f", p.scalef )
		p.v = p.scalef
	end
end
-- ============================================================================
function tosc_show_widget(self)
	tx=self:root() tx:send (self:path() .. "/visible", "i", 1)
end
-- ============================================================================
function tosc_hide_widget(self)
	tx=self:root() tx:send (self:path() .. "/visible", "i", 0 )
end
-- ============================================================================
function tosc_set_widget_visible(self, visible)
	tx=self:root() tx:send (self:path() .. "/visible", "i", ibool(visible) )
end
-- ============================================================================
function tosc_set_widget_color(self, color)
	tx=self:root() tx:send (self:path() .. "/color", "s", color )
end
-- ============================================================================
function tosc_set_widget_x(self, x)
	tx=self:root() tx:send (self:path() .. "/position/x", "i", x )
end
-- ============================================================================
function tosc_set_widget_y(self, y)
	tx=self:root() tx:send (self:path() .. "/position/y", "i", y )
end
-- ============================================================================
function tosc_set_widget_position(self, x, y)
	tosc_set_widget_x(self, x)
	tosc_set_widget_y(self, y)
end
-- ============================================================================
function tosc_set_widget_z(self, z)
	tx=self:root() tx:send (self:path() .. "/position/z", "i", z )
end
-- ============================================================================
function tosc_set_widget_width(self, width)
	tx=self:root() tx:send (self:path() .. "/size/w", "i", width )
end
-- ============================================================================
function tosc_set_widget_height(self, height)
	tx=self:root() tx:send (self:path() .. "/size/h", "i", height )
end
-- ============================================================================
function tosc_set_widget_size(self, width, height)
	tosc_set_widget_width(self, width)
	tosc_set_widget_height(self, height)
end
-- ============================================================================
function tosc_set_widget_off(self)
	self:send ("f", self.props.scalef)
	self.props.v=self.props.scalef
end
-- ============================================================================
function tosc_set_widget_on(self)
	self:send ("f", self.props.scalet )
	self.props.v=self.props.scalet
end
-- ============================================================================
function tosc_set_label(self,t)
	self:send ("s", t )
end
-- ============================================================================
function tosc_set_widget_value(self,f)
	self:send ("f", f )
	self.props.v=f
end
-- ============================================================================
function tosc_set_led(self,f)
	if f < 0 then f = 0 end
	if f > 1 then f = 1 end
	self:send ("f", f )
	self.props.v=f
end
-- ============================================================================
function tosc_set_button(self,b)
	if b then self:send ("f", 1 ) self.props.v=1
	else self:send ("f", 0 ) self.props.v=0 end
end

-- functions used to populate model{}
-- called from gen.lua tosc_build_surface()
-- ============================================================================
-- ============================================================================
function tosc_add_layout_data(model, base64_string)
	if model['props'] == nil then model['props']={} end
	model['props']['layout_data']=base64_string
end
-- ============================================================================
function tosc_set_surface_address(model, host, port)
	if model['props'] == nil then model['props']={} end
	model['props']['active_tab']=""

	local tx_uri="osc.udp://" .. host .. ":" .. port
	model['props']['tx_uri']=tx_uri
	local tx = ARDOUR.LuaOSC.Address (tx_uri)
	model['props']['tx']=tx
	function model:dump() print_r(self) end
	function model:send(path, types, ...) self.props.tx:send(path, types, ...) end
	function model:active_tab() return self.props.active_tab end
end
-- ============================================================================
function tosc_add_tab(model,name,path)
	--reserved word
	if name == 'props' then print("can't add tab named props") return 0 end

	--if tab not yet defined
	if model[name] == nil then model[name]={} end
	--create table to hold props
	if model[name]['props'] == nil then model[name]['props']={} end
	-- set name
	model[name]['props']['n']=name
	--set path
	model[name]['props']['path']=path
	model[name]['props']['type']='tab'
	--will be used as function name for the osc callback mapping
	model[name]['props']['random']="_cso_" .. string.random(20) .. ARDOUR.LuaAPI:monotonic_time()

	tab=model[name]
	function tab:dump() return print_r(self) end
	function tab:path() return self.props.path end
	function tab:type() return self.props.type end
	function tab:parent() return model end
	function tab:root() return model end
	--//hiding self:path() from caller
	function tab:send(types, ...) local tx=self:root() tx:send(self:path(), types, ...) end
	function tab:activate() return tosc_activate_tab(self) end
end

-- ============================================================================
function tosc_add_widget(model, table)
	--table must have at least attributes tab and n (=name_plain)
	if table.tab and table.n and table.type and model[table.tab] then
		--create a ~'namespace' for this widget to hold functions and properties
		model[table.tab][table.n]={}
		--assign table (key=value array) to widget.props in model (prevent name clashes with function names)
		model[table.tab][table.n]['props']=table
		model[table.tab][table.n]['props']['random']="_cso_" .. string.random(20)

		widget=model[table.tab][table.n]
		function widget:dump() return print_r(self) end
		function widget:path() return self.props.path end
		function widget:type() return self.props.type end
		function widget:parent() return model[table.tab] end
		function widget:root() return model end
		function widget:send(types, ...) tx=self:root() tx:send(self:path(), types, ...) end
		function widget:reset() return tosc_reset_widget(self) end
		function widget:show() return tosc_show_widget(self) end
		function widget:hide() return tosc_hide_widget(self) end
		function widget:set_visible(visible) return tosc_set_widget_visible(self,visible) end
		function widget:set_color(c) return tosc_set_widget_color(self,c) end
		function widget:set_x(x) return tosc_set_widget_x(self,x) end
		function widget:set_y(y) return tosc_set_widget_y(self,y) end
		function widget:set_position(x,y) return tosc_set_widget_position(self,x,y) end
		function widget:set_z(z) return tosc_set_widget_z(self,z) end
		function widget:set_width(w) return tosc_set_widget_width(self,w) end
		function widget:set_height(h) return tosc_set_widget_height(self,h) end
		function widget:set_size(w,h) return tosc_set_widget_size(self,w,h) end

--		if widget.props.scalef then end
		if widget:type() == "toggle" or widget:type() == "push" then
			function widget:set(b) return tosc_set_button(self,b) end
			function widget:on() return tosc_set_widget_on(self) end
			function widget:off() return tosc_set_widget_off(self) end
			function widget:is_on() return self.props.v and      self.props.v == 1 end
			function widget:is_off() return self.props.v and not(self.props.v == 1) end
		elseif widget:type() == "led" then
			function widget:set(f) return tosc_set_led(self,f) end
		elseif widget:type() == "rotaryv" or widget:type() == "rotaryh" 
			or widget:type() == "faderv" or widget:type() == "faderh" then
			function widget:set(f) return tosc_set_widget_value(self,f) end
		elseif widget:type() == "labelh" or widget:type() == "labelv" then
			function widget:set(t) return tosc_set_label(self,t) end
		end
	end
end
--tosc_add_widget()

--EOF
