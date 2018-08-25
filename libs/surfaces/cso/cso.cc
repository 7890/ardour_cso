/*
 * Copyright (C) 2006 Paul Davis
 * Copyright (C) 2017 Thomas Brand
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#include <cstdio>
#include <cstdlib>
#include <unistd.h>

#include <pbd/failed_constructor.h>

#include <fcntl.h>
#include <glib.h>
#include "pbd/gstdio_compat.h"

#include "ardour/session.h"
#include "ardour/search_paths.h"
#include "pbd/file_utils.h"
#include "cso.h"
#include "pbd/i18n.h"

using namespace ARDOUR;
using namespace std;
using namespace Glib;
using namespace ArdourSurface;

#include "pbd/abstract_ui.cc" // instantiate template

CSO* CSO::cso_instance = 0;

#ifdef DEBUG
static void error_callback(int num, const char *m, const char *path)
{
	fprintf(stderr, "CSO::liblo server error %d in path %s: %s\n", num, path, m);
}
#else
static void error_callback(int, const char *, const char *){}
#endif

//=============================================================================
//=============================================================================
CSO::CSO (Session& s)
	: ControlProtocol (s, X_("Control Surface Object (CSO)"))
	, AbstractUI<CSORequest> (name())
	, osc_server_port (9999) //will be read from cso_params
	, osc_server (0)

	//default path values, will be updated using lua_search_path ()
	, cso_home_path ("/tmp/cso")
	, cso_start_script_uri ("/tmp/cso/start.lua")
	, cso_custom_script_uri ("/tmp/cso/null/null.lua")

	, osc_debug_enabled (false)
	, lua_print_stderr_enabled (true)
	, lua_print_osc_enabled (false)
	, timer1_interval_ms (250)
{
	fprintf(stderr,"CSO::constructor\n");
	fprintf(stderr,"\n  ====    ====    ====  \n ==  ==  ==  ==  ==  == \n ==      ==      ==  == \n ==       ====   ==  == \n ==          ==  ==  == \n ==  ==  ==  ==  ==  == \n  ====    ====    ====  \n Control Surface Object \n\n");

	cso_instance = this;

	//set with /connect (si)
	feedback_address=lo_address_new("localhost", "9000");
	//set with /print/osc/address si
	print_address=lo_address_new("localhost", "9001");

	lua_init();
	//lua code that sends out osc early should be called in start() after osc server is created
	//this way the messages will be sent from the configured osc server port
}

//=============================================================================
CSO::~CSO()
{
	fprintf(stderr,"CSO::destructor\n");
	stop ();
	cso_instance = 0;
}

//=============================================================================
void*
CSO::request_factory (uint32_t num_requests)
{
	return request_buffer_factory (num_requests);
}

//=============================================================================
void
CSO::do_request (CSORequest * req)
{
	fprintf(stderr,"CSO::do_request()\n");
	if (req->type == CallSlot)
	{
		call_slot (MISSING_INVALIDATOR, req->the_slot);
	}
	else if (req->type == Quit)
	{
		stop();
	}
}

//=============================================================================
int
CSO::set_active (bool yn)
{
	fprintf(stderr,"CSO::set_active(%s)\n", yn ? "true" : "false");
	if (yn == active())
	{
		fprintf(stderr,"CSO::already active, nothing to do\n");
		return 0;
	}
	if (yn)
	{
		if (start () != 0 ) 
		{
			return -1;
		}
	}
	//setting private _active
	ControlProtocol::set_active (yn);
	return 0;
}

//=============================================================================
bool
CSO::get_active () const
{
	return osc_server != 0 && active();
}

//=============================================================================
int
CSO::start ()
{
	fprintf(stderr,"CSO::start()\n");
	if (osc_server) {
		//already started
		return 0;
	}

	fprintf(stderr, "CSO::trying to create osc server on port %d\n", osc_server_port);

	//create char from int for lo_server_new
	char udp_port[255];
	snprintf(udp_port, sizeof(udp_port), "%d", osc_server_port);

	osc_server=lo_server_new(udp_port, error_callback);

	if (!osc_server) {
		fprintf(stderr, "CSO::failed to create osc server\n");
		return 1;
	}

	register_osc_callbacks();

	//startup the event loop thread
	//without this: connected signals won't be received
	BaseUI::run ();

	//call into lua
	on_signal_generic("cso_start");

	//a single multi-purpose timer (for periodic updates like clock/timecode, metering, heartbeat ..)
	//don't setup timer if interval set to 0
	if(timer1_interval_ms > 0)
	{
		Glib::RefPtr<Glib::TimeoutSource> timer1 = Glib::TimeoutSource::create (timer1_interval_ms);
		periodic_connection = timer1->connect (sigc::mem_fun (*this, &CSO::cb_timer1));
		timer1->attach (main_loop()->get_context());
	}

	register_signal_callbacks();

	fprintf(stderr, "CSO::ready\n");
	return 0;
} //start()

//=============================================================================
int
CSO::stop ()
{
	fprintf(stderr,"CSO::stop\n");
	session_connections.drop_connections ();
	//call into lua
	on_signal_generic("cso_shutdown");
	BaseUI::quit ();
	lo_server_free(osc_server);
	fprintf(stderr,"CSO::cleaned up\n");
	return 0;
}

//=============================================================================
XMLNode&
CSO::get_state ()
{
	XMLNode& node (ControlProtocol::get_state());
	///node.set_property ("cso_control_protocol_property", 42);
	return node;
}

//=============================================================================
int
CSO::set_state (const XMLNode& node, int version)
{
	if (ControlProtocol::set_state (node, version))
	{
		return -1;
	}
	return 0;
}

//=============================================================================
void
CSO::thread_init ()
{
	fprintf(stderr,"CSO::thread_init: %s\n", event_loop_name().c_str());
	pthread_set_name (event_loop_name().c_str());
	if (osc_server)
	{
		Glib::RefPtr<IOSource> src = IOSource::create (lo_server_get_socket_fd (osc_server), IO_IN|IO_HUP|IO_ERR);
		src->connect (sigc::bind (sigc::mem_fun (*this, &CSO::osc_input_handler), osc_server));
		src->attach (_main_loop->get_context());
	}
	PBD::notify_event_loops_about_thread_creation (pthread_self(), event_loop_name(), 2048);
	ARDOUR::SessionEvent::create_per_thread_pool (event_loop_name(), 128);
}

//=============================================================================
bool
CSO::osc_input_handler (IOCondition ioc, lo_server srv)
{
	if (ioc & ~IO_IN) {
		return false;
	}

	//receive/process osc data if available
	if (ioc & IO_IN) {
		//registered osc handlers will eventually be called
		lo_server_recv (srv);
	}

	return true;
}

//=============================================================================
void
CSO::register_signal_callbacks()
{
	//connect to state changes and bind to callback methods
	//!\ this list is not complete
	session->TransportStateChange.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_transport_state_changed, this), this);
	session->RecordStateChanged.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_record_state_changed, this), this);
	session->Exported.connect (*this, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_session_exported, this, _1, _2), this);
	session->RouteAdded.connect(session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_route_added, this, _1), this);
	session->RouteGroupPropertyChanged.connect(session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_route_group_property_changed, this, _1), this);
	session->DirtyChanged.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_dirty_state_changed, this), this);
	session->StateSaved.connect(session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_state_saved, this, _1), this);
	session->SoloActive.connect(session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_solo_state_changed, this, _1), this);
	//session config param (Session/Properties)
	session->config.ParameterChanged.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_config_parameter_changed, this, _1), this);
	//global config (Edit/Preferences)
	Config->ParameterChanged.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_config_parameter_changed, this, _1), this);
	//emitted when the loop begins at the start again
	session->TransportLooped.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_looped, this), this);
	session->Located.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_session_located, this), this);
	///..in session_connections
	///ControlProtocol::StripableSelectionChanged.connect (session_connections, MISSING_INVALIDATOR, boost::bind (&CSO::on_signal_stripable_selection_changed, this), this);
	//see gtk2_ardour/luasignal_syms.h for inspiration
}

//=============================================================================
//=============================================================================
#define CSO_ADD_OSC_HANDLER(path, types, name) \
	lo_server_add_method(osc_server, path, types, CSO::_ ## name, this);
	//last param 'this' (void *user_data) passes a reference to the 
	//static _osc_* methods on every call

void
CSO::register_osc_callbacks()
{
	//when adding new handlers:
	//dont forget to add corresponding CSO_STATIC_TO_MEMBER_CB_PAIR(name) in cso.h
//grep tag for poor mans documentation
//__SOSC
	// "s": lua string
	CSO_ADD_OSC_HANDLER("/eval",            "s",    osc_eval);

	// "sss": path, types, lua function name
	CSO_ADD_OSC_HANDLER("/map/add",         "sss",  osc_map_add);

	// "ss": path, types
	CSO_ADD_OSC_HANDLER("/map/remove",      "ss",   osc_map_remove);

	// (no arguments)
	CSO_ADD_OSC_HANDLER("/map/clear",       "",     osc_map_clear);

	// (no arguments)
	CSO_ADD_OSC_HANDLER("/map/dump",        "",     osc_map_dump);

	// (no arguments): set feedback address to host and port from requester
	// "si": host, port
	CSO_ADD_OSC_HANDLER("/connect",         NULL,   osc_connect);

	// turn on/off CSO debug output
	// accepts i,T,F
	CSO_ADD_OSC_HANDLER("/debug",           NULL,   osc_debug);

	// turn on/off print() to stderr from lua
	// accepts i,T,F
	CSO_ADD_OSC_HANDLER("/print/stderr",    NULL,   osc_print);

	// turn on/off print() to osc address from lua
	// accepts i,T,F
	CSO_ADD_OSC_HANDLER("/print/osc",       NULL,   osc_print_osc);

	// set destination osc host to send print() as string
	CSO_ADD_OSC_HANDLER("/print/osc/address", "si", osc_print_osc_address);

	// the above pathes can't be re-defined in lua.
	// the rest of the osc path namespace can be freely used and i.e. bound to lua functions.

	// NULL, NULL: match all paths, all types
	CSO_ADD_OSC_HANDLER(NULL,               NULL,   osc_catchall);

	// examples
	// ========

	// set surface address (i.e. oscdump in another terminal for testing):
	//   /connect si localhost 9001

	// add lua function:
	//   /eval s "function foo(x) print('hello from lua ' .. x) end"

	// bind osc message /bar i to foo(x):
	//   /map/add sss "/bar" "i" "foo"

	// call foo:
	//   /bar i 42

	// get custom feedback (can be put to a bound function, also see /connect):
	//   /eval s "sendme('/pos', 'i', Session:transport_frame())"

	// default CSO OSC port is 9999 (UDP)
	// default CSO surface address is localhost:9000 (UDP)

	// see http://manual.ardour.org/lua-scripting/
	// see http://manual.ardour.org/lua-scripting/class_reference/
//__EOSC
}

//=============================================================================
int
CSO::cb_osc_eval (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	fprintf(stderr,"CSO::eval\n");
	string lua_script=&argv[0]->s;
	lua.do_command(lua_script);
	return 0;
}

//=============================================================================
int
CSO::cb_osc_map_add (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	//create mapping: path, typetag, lua_function
	OSCMapping *o = new OSCMapping(string(&argv[0]->s), string(&argv[1]->s), string(&argv[2]->s));

	stringstream ss;
	ss << &argv[0]->s << ";" << string(&argv[1]->s);
	string path_type_concat=ss.str(); //pseudo hash
	fprintf(stderr, "CSO::add mapping %s -> %s\n", path_type_concat.c_str(), &argv[2]->s);

	//delete any existing equal key (replace with new)
	osc_map.erase(path_type_concat);
	//add mapping to map
	osc_map.insert(OSCMapPair(path_type_concat,o));
	return 0;
}

//=============================================================================
int
CSO::cb_osc_map_remove (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	stringstream ss;
	ss << &argv[0]->s << ";" << string(&argv[1]->s);
	string path_type_concat=ss.str();
	fprintf(stderr, "CSO::remove mapping %s\n", path_type_concat.c_str());
	osc_map.erase(path_type_concat);
	return 0;
}

//=============================================================================
int
CSO::cb_osc_map_clear (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	fprintf(stderr, "CSO::clear map\n");
	osc_map.clear();
	return 0;
}

//=============================================================================
int
CSO::cb_osc_map_dump (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	fprintf(stderr, "CSO::start of map\n");
	map<string, OSCMapping*>::iterator it;
	for (it=osc_map.begin(); it!=osc_map.end(); ++it)
	{
		fprintf(stderr, "%s -> %s\n", it->first.c_str(), ((OSCMapping*)it->second)->method.c_str());
	}
	fprintf(stderr, "CSO::end of map\n");
	return 0;
}

//=============================================================================
int
CSO::cb_osc_connect (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	if(argc==0)
	{
		set_feedback_address(lo_message_get_source(msg));
	}
	else if(strcmp (types, "si") == 0)
	{
		set_feedback_address(lo_address_from_argv_si(types, argv, argc));
	}
	return 0;
}

//=============================================================================
int
CSO::cb_osc_debug (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	string status=set_bool_from_int(&osc_debug_enabled, int_from_argv_iTF(types, argv, argc));
	fprintf(stderr, "CSO::debug is %s\n", status.c_str());
	return 0;
}

//=============================================================================
int
CSO::cb_osc_print (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	string status=set_bool_from_int(&lua_print_stderr_enabled, int_from_argv_iTF(types, argv, argc));
	fprintf(stderr, "CSO::print (stderr) is %s\n", status.c_str());
	return 0;
}

//=============================================================================
int
CSO::cb_osc_print_osc (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	string status=set_bool_from_int(&lua_print_osc_enabled, int_from_argv_iTF(types, argv, argc));
	fprintf(stderr, "CSO::print (osc) is %s\n", status.c_str());
	return 0;
}

//=============================================================================
int
CSO::cb_osc_print_osc_address (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	if(argc==0)
	{
		set_print_address(lo_message_get_source(msg));
	}
	else if(strcmp (types, "si") == 0)
	{
		set_print_address(lo_address_from_argv_si(types, argv, argc));
	}
	return 0;
}

//=============================================================================
void
CSO::set_feedback_address (lo_address addr)
{
	feedback_address=addr;
	fprintf(stderr,"CSO::feedback address set to: %s:%s\n"
		,lo_address_get_hostname(feedback_address)
		,lo_address_get_port(feedback_address)
	);

	//call into lua so surface integration scripts can use feedback address
	string fname="cso_on_feedback_address_changed";
	luabridge::LuaRef lua_ref = luabridge::getGlobal (L, fname.c_str());
	if(lua_ref.isFunction())
	{
		lua_ref( lo_address_get_hostname(feedback_address)
			,lo_address_get_port(feedback_address)
		);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::set_print_address (lo_address addr)
{
	print_address=addr;
	fprintf(stderr,"CSO::print (osc) address set to: %s:%s\n"
		,lo_address_get_hostname(print_address)
		,lo_address_get_port(print_address)
	);

	//call into lua so surface integration scripts can use feedback address
	string fname="cso_on_print_address_changed";
	luabridge::LuaRef lua_ref = luabridge::getGlobal (L, fname.c_str());
	if(lua_ref.isFunction())
	{
		lua_ref( lo_address_get_hostname(print_address)
			,lo_address_get_port(print_address)
		);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void 
CSO::lua_push_lo_type(OSCMapping *mapping, lo_arg **argv, uint32_t argno)
{
	///TRUE / FALSE / NIL etc need special handling (unless passed as args)
	if(argno >= mapping->types.length())
	{
		return;
	}

	lo_type type = (lo_type)mapping->types.at(argno);
	switch (type)
	{
		//!\ this list does not cover all possible OSC types
		case LO_INT32:
			lua_pushnumber(L,argv[argno]->i);
			break;
		case LO_INT64:
			lua_pushnumber(L,argv[argno]->h);
			break;
		case LO_FLOAT:
			lua_pushnumber(L,argv[argno]->f);
			break;
		case LO_DOUBLE:
			lua_pushnumber(L,argv[argno]->d);
			break;
		case LO_STRING:
			lua_pushstring(L,&argv[argno]->s);
			break;
		case LO_CHAR:
			lua_pushstring(L,&argv[argno]->s);
			break;
		case LO_TRUE:
			lua_pushboolean(L,true);
			break;
		case LO_FALSE:
			lua_pushboolean(L,false);
			break;
		///
		default:
			fprintf(stderr,"CSO::error: OSC type is not supported\n");
			break;
	}
} //lua_push_lo_type()

//=============================================================================
int
CSO::cb_osc_catchall (const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
{
	//try to find a custom mapping for a message that wasn't processed by any previous handlers
	stringstream ss;
	ss << path << ";" << types;
	string path_type_concat=ss.str();

	if (osc_map.count(path_type_concat) > 0) //found
	{
		OSCMapping *o=osc_map.at(path_type_concat);
		int nargs=o->types.length();
		string fname=o->method;
		fprintf(stderr, "CSO::trying to call method %s with %d args (%s)\n", fname.c_str(), nargs, o->types.c_str());

		///need solution for a.b.c:d() calls. for now must be wrapped with "flat" method.
		///http://stackoverflow.com/questions/1888672/calling-functions-in-a-lua-table-from-c

		luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
		if(lua_ref.isFunction ())
		{
			//function to be called
			lua_getglobal(L, fname.c_str());
			//immediately followed by pushing args to lua stack for this method
			for(int w=0; w<nargs; w++)
			{
				//push typed args according to lo_type
				lua_push_lo_type(o,argv,w);
			}
			//execute
			if (lua_pcall(L, nargs, 0, 0) != 0) //0==success
			{
				fprintf(stderr, "CSO::failed to call lua function %s:\n%s\n", fname.c_str()
					,lua_tostring(L, -1));
			}
			//no return value expected (methods will talk back OSC if at all)

		}else{warn_lua_function_not_found(fname);}
	}
	else
	{
		fprintf(stderr, "CSO::warning: no mapping found for %s\n", path_type_concat.c_str());
		/*
		if(osc_notify_unknown_message)
		{
			//...
		}
		*/
	}

	if(osc_debug_enabled)
	{
		debugmsg ("CSO::OSC", path, types, argv, argc, msg);

		int msg_length=lo_message_length(msg,path);
		void * msg_bytes=calloc(msg_length,sizeof(char));
		size_t size_ret;
		lo_message_serialise (msg, path, msg_bytes, &size_ret);
		hexdump((uint8_t*)msg_bytes,size_ret);
		free(msg_bytes);
	}

	return 0; //1: unhandled / try next
} //cb_osc_catchall()

//=============================================================================
//=============================================================================
//=============================================================================
bool
CSO::set_script_uri_and_path()
{
	vector<string> files;
	PBD::Searchpath search_path (lua_search_path ());
	search_path.add_subdirectory_to_paths ("cso");
	PBD::find_files_matching_pattern (files, search_path, "start.lua");
	if(files.size()<1){return false;}

	fprintf(stderr,"CSO::looking for start.lua in lua_search_path subdir 'cso':\n%s\n"
		,search_path.to_string().c_str());

	//check that g_open will successfully open the file
	for (vector<string>::iterator i = files.begin (); i != files.end (); ++i)
	{
		string input_path = *i;
		fprintf(stderr,"CSO::found start.lua: %s\n", input_path.c_str());

		int fdgo = g_open (input_path.c_str(), O_RDONLY, 0444);
		if(fdgo==-1){return false;}

		//if file could be opened in read mode, close it again
		if(fdgo>=0){::close (fdgo);}

		//set start uri and cso home
		cso_start_script_uri=input_path;
		cso_home_path=Glib::path_get_dirname(cso_start_script_uri);
		return true;
	}
	return false;
	/*
	//inspiration
	if ((s = getenv ("ENV_VAR"))) {}
	PBD::Searchpath control_protocol_search_path ()
	int const r = symlink ("bar", "foo/jim");
	if (g_mkdir_with_parents ("foo/bar/baz", 0755) == 0);
	*/
} //set_script_uri_and_path()

//=============================================================================
void
CSO::lua_init ()
{
	//connect the print() method
	lua.Print.connect(sigc::mem_fun(*this, &CSO::lua_print));

	L = lua.getState ();

	//see libs/ardour/luabindings.cc for details on the following bindings:
	LuaBindings::stddef (L);
	LuaBindings::common (L);
//	LuaBindings::dsp (L);
	LuaBindings::osc (L);
	LuaBindings::session (L);
	LuaBindings::set_session (L, session);

	//bind functions from BasicUI that are convenient but not available via Session:
	//this is a selection from libs/surfaces/control_protocol/control_protocol/basic_ui.h
	luabridge::getGlobalNamespace(L)
		.beginNamespace("Surface")
			.beginClass<BasicUI>("BasicUI")
				//from BasicUI::
				//access_action: see manual.ardour.org/appendix/menu-actions-list/
				.addFunction("access_action", &BasicUI::access_action)

				//transport
				.addFunction("transport_stop", &BasicUI::transport_stop)
				.addFunction("transport_play", &BasicUI::transport_play) //bool jump_back = false (?)
				.addFunction("set_transport_speed", &BasicUI::set_transport_speed) //double speed
				.addFunction("goto_zero", &BasicUI::goto_zero)
				.addFunction("goto_start", &BasicUI::goto_start) //bool and_roll = false
				.addFunction("goto_end", &BasicUI::goto_end)
				.addFunction("rewind", &BasicUI::rewind)
				.addFunction("ffwd", &BasicUI::ffwd)
				.addFunction("jump_by_seconds", &BasicUI::jump_by_seconds) //double sec
				.addFunction("jump_by_bars", &BasicUI::jump_by_bars) //double bars
				//double is misleading, jumping by 1.7 bars isn't possible
				//jump_by_beats is missing
				//setting ranges from selection
				.addFunction("set_punch_range", &BasicUI::set_punch_range)
				.addFunction("set_loop_range", &BasicUI::set_loop_range)
				.addFunction("set_session_range", &BasicUI::set_session_range)
				.addFunction("loop_toggle", &BasicUI::loop_toggle)
				.addFunction("toggle_loop", &BasicUI::loop_toggle) //alias
				.addFunction("loop_location", &BasicUI::loop_location) //framepos_t start, framepos_t end
				.addFunction("toggle_punch_in", &BasicUI::toggle_punch_in)
				.addFunction("toggle_punch_out", &BasicUI::toggle_punch_out)
				.addFunction("locate", &BasicUI::locate) //framepos_t frame, bool play = false

				//markers
				.addFunction("add_marker", &BasicUI::add_marker ) //string markername
				.addFunction("remove_marker_at_playhead", &BasicUI::remove_marker_at_playhead)
				.addFunction("prev_marker", &BasicUI::prev_marker)
				.addFunction("next_marker", &BasicUI::next_marker)
				.addFunction("goto_nth_marker", &BasicUI::goto_nth_marker ) //int n

				.addFunction("save_state", &BasicUI::save_state)
				.addFunction("undo", &BasicUI::undo)
				.addFunction("redo", &BasicUI::redo)
				.addFunction("mark_in", &BasicUI::mark_in)
				.addFunction("mark_out", &BasicUI::mark_out)
				.addFunction("toggle_click", &BasicUI::toggle_click)
				.addFunction("midi_panic", &BasicUI::midi_panic)
				.addFunction("toggle_monitor_mute", &BasicUI::toggle_monitor_mute)
				.addFunction("toggle_monitor_dim", &BasicUI::toggle_monitor_dim)
				.addFunction("toggle_monitor_mono", &BasicUI::toggle_monitor_mono)
				.addFunction("cancel_all_solo", &BasicUI::cancel_all_solo)
				.addFunction("quick_snapshot_stay", &BasicUI::quick_snapshot_stay) //?
				.addFunction("quick_snapshot_switch", &BasicUI::quick_snapshot_switch) //?
				//this provides the same operation as the "spacebar", it's a lot smarter than "play".
				.addFunction("toggle_roll", &BasicUI::toggle_roll)
				//stop ongoing recording and forget about it (all recordings LOST / not stored to disk)
				.addFunction("stop_forget", &BasicUI::stop_forget)
				//set master record enable/disable
				.addFunction("set_record_enable", &BasicUI::set_record_enable)// bool yn
				//master record
				.addFunction("rec_enable_toggle", &BasicUI::rec_enable_toggle)
				//this function does currently nothing in BasicUI
				//.addFunction("toggle_all_rec_enables", &BasicUI::toggle_all_rec_enables)
				.addFunction("all_tracks_rec_enable", &BasicUI::all_tracks_rec_in)
				.addFunction("all_tracks_rec_in", &BasicUI::all_tracks_rec_in)
				.addFunction("all_tracks_rec_disable", &BasicUI::all_tracks_rec_out)
				.addFunction("all_tracks_rec_out", &BasicUI::all_tracks_rec_out)

				//editor visibility stuff
				//(why do we have to make explicit numbers here?  because "gui actions" don't accept args
				.addFunction("fit_1_track", &BasicUI::fit_1_track)
				.addFunction("fit_2_tracks", &BasicUI::fit_2_tracks)
				.addFunction("fit_4_tracks", &BasicUI::fit_4_tracks)
				.addFunction("fit_8_tracks", &BasicUI::fit_8_tracks)
				.addFunction("fit_16_tracks", &BasicUI::fit_16_tracks)
				.addFunction("fit_32_tracks", &BasicUI::fit_32_tracks)
				.addFunction("fit_all_tracks", &BasicUI::fit_all_tracks)
				.addFunction("zoom_10_ms", &BasicUI::zoom_10_ms)
				.addFunction("zoom_100_ms", &BasicUI::zoom_100_ms)
				.addFunction("zoom_1_sec", &BasicUI::zoom_1_sec)
				.addFunction("zoom_10_sec", &BasicUI::zoom_10_sec)
				.addFunction("zoom_1_min", &BasicUI::zoom_1_min)
				.addFunction("zoom_5_min", &BasicUI::zoom_5_min)
				.addFunction("zoom_10_min", &BasicUI::zoom_10_min)
				.addFunction("zoom_to_session", &BasicUI::zoom_to_session)
				.addFunction("temporal_zoom_in", &BasicUI::temporal_zoom_in)
				.addFunction("temporal_zoom_out", &BasicUI::temporal_zoom_out)
				.addFunction("scroll_up_1_track", &BasicUI::scroll_up_1_track)
				.addFunction("scroll_dn_1_track", &BasicUI::scroll_dn_1_track)
				.addFunction("scroll_down_1_track", &BasicUI::scroll_dn_1_track) //alias
				.addFunction("scroll_up_1_page", &BasicUI::scroll_up_1_page)
				.addFunction("scroll_down_1_page", &BasicUI::scroll_dn_1_page) //alias
				.addFunction("scroll_dn_1_page", &BasicUI::scroll_dn_1_page)

				//.addFunction("timecode_time", &BasicUI::timecode_time  )//(framepos_t where, Timecode::Time&);
				//.addFunction("timecode_to_sample", &BasicUI::timecode_to_sample  )//(Timecode::Time& timecode, framepos_t & sample, bool use_offset, bool use_subframes) const;
				//.addFunction("sample_to_timecode", &BasicUI::sample_to_timecode  )//(framepos_t sample, Timecode::Time& timecode, bool use_offset, bool use_subframes) const;
			.endClass()
		.endNamespace();

	luabridge::push <BasicUI *> (L, this);
	lua_setglobal(L, "CSO");
	//in lua: CSO:access_action(...)

	//create reference to useful os functions (before setting io to nil)
	lua.do_command("local tmpref1=os.date local tmpref2=os.time os = {} os.date=tmpref1 os.time=tmpref2");

	//prevent use of some built-in lua functions (os reduced to os.date see above)
	lua.do_command ("io = nil          loadfile = nil require = nil dofile = nil package = nil debug = nil");

	//currently unused
	//in the script: ardour {...}
	lua.do_command (
			"ardourluainfo = {}"
			"function ardour (entry)"
			"  ardourluainfo['type'] = assert(entry['type'])"
			"  ardourluainfo['name'] = assert(entry['name'])"
			"  ardourluainfo['category'] = entry['category'] or 'Unknown'"
			"  ardourluainfo['author'] = entry['author'] or 'Unknown'"
			"  ardourluainfo['license'] = entry['license'] or ''"
			"  ardourluainfo['description'] = entry['description'] or ''"
			" end"
			);

	//load functions cso_base64_dec cso_base64_dec into lua env
	lua.do_command(CSO_BASE64);
	//load and evaluate base64 encoded string (cso.lua)
	//once this is loaded cso is ready yet in a generic state
	lua.do_command("load(cso_base64_dec('" + CSO_SCRIPT + "'))()");

	//find start.lua via ardour path / search methods
	if(!set_script_uri_and_path())
	{
		fprintf(stderr,"CSO::Error: could not find start.lua in search path\n");
	}
/*
	-- start script syntax
	function cso_custom_script_uri()
	{{
		uri_relative="cso/null/null.lua"
	}}
*/
	lua.do_file(cso_start_script_uri);

	string fname="cso_custom_script_uri";
	luabridge::LuaRef lua_start_params = luabridge::getGlobal (L, fname.c_str());
	if(lua_start_params.isFunction ())
	{
		luabridge::LuaRef params = lua_start_params ();
		if (params.isTable ())
		{
			for (luabridge::Iterator it (params); !it.isNil (); ++it)
			{
				if (it.value ()["uri_relative"].isString ())
				{
					string uri_relative=it.value()["uri_relative"].cast<string>();
					cso_custom_script_uri=Glib::build_filename(cso_home_path, uri_relative);
					break;
				}
			}
		}
	}else{warn_lua_function_not_found(fname);}

	//load script specific to surface / layout.
	//the namespace is shared with the cso script.
	//**functions can be overridden.**
	//this file can load other lua snippets ~libraries via the cso_params 'loadlibs' table.
	fprintf(stderr,"CSO::LOAD CUSTOM SCRIPT %s\n", cso_custom_script_uri.c_str());
	lua.do_file(cso_custom_script_uri);
	//now all lua code (except includes) is known to the scripting environment.

	//start to call methods and setup cso and the surface
	fname="cso_params";
	luabridge::LuaRef lua_params = luabridge::getGlobal (L, fname.c_str());
	if(lua_params.isFunction ()) 
	{
		luabridge::LuaRef params = lua_params ();
		if (params.isTable ())
		{
			for (luabridge::Iterator it (params); !it.isNil (); ++it)
			{
				if (it.value ()["osc_server_port"].isNumber ())
				{
					osc_server_port=it.value()["osc_server_port"].cast<int>();
				}
				if (it.value ()["osc_debug"].isBoolean ())
				{
					osc_debug_enabled=it.value()["osc_debug"].cast<bool>();
				}
				if (it.value ()["timer1_interval_ms"].isNumber ())
				{
					timer1_interval_ms=it.value()["timer1_interval_ms"].cast<int>();
				}
				if (it.value ()["loadlibs"].isTable ())
				{
					//read table loadlibs={'foo.lua','bar/baz.lua'}
					luabridge::LuaRef libs (it.value()["loadlibs"]);

					for (luabridge::Iterator i (libs); !i.isNil (); ++i)
					{
						if (!i.key ().isNumber ()) { continue; }
						if (!i.value ().isString ()) { continue; }

						string script_uri_relative
							=i.value().cast<std::string>().c_str();
						string cso_load_additional_script_uri
							=Glib::build_filename(cso_home_path, script_uri_relative);

						fprintf(stderr,"CSO::LOADLIBS %d %s\n"
							,i.key().cast<int>()
							,cso_load_additional_script_uri.c_str());
						lua.do_file(cso_load_additional_script_uri);
					}
				}
			}
		} //is table
		else
		{
			fprintf(stderr, "CSO::error: failed to read %s table\n", fname.c_str());
		}
	}else{warn_lua_function_not_found(fname);}

	fname="cso_init";
	luabridge::LuaRef lua_ref = luabridge::getGlobal (L, fname.c_str());
	if(lua_ref.isFunction())
	{
		lua_ref(CSO_API_VERSION, osc_server_port);
	}else{warn_lua_function_not_found(fname);}
} //lua_init()

//=============================================================================
void
CSO::lua_print (string s)
{
	if(lua_print_stderr_enabled)
	{
		fprintf(stderr,"CSO::LuaProc: %s\n", s.c_str());
	}
	if(lua_print_osc_enabled)
	{
		if(print_address!=0)
		{
			lo_send(print_address, "/print", "s", s.c_str());
		}
	}
}

//=============================================================================
void
CSO::warn_lua_function_not_found (string function_name)
{
	fprintf(stderr, "CSO::warning: lua function '%s' not found\n", function_name.c_str());
}

//=============================================================================
bool
CSO::on_signal_generic(string lua_function_name)
{
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, lua_function_name.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref();
		return true;
	}else{warn_lua_function_not_found(lua_function_name);}
	return false;
}

//=============================================================================
void
CSO::on_signal_transport_state_changed()
{
	on_signal_generic("on_ardour_transport_state_changed");
}

//=============================================================================
void
CSO::on_signal_record_state_changed()
{
	on_signal_generic("on_ardour_record_state_changed");
}

//=============================================================================
void
CSO::on_signal_looped ()
{
	on_signal_generic("on_ardour_looped");
}

//=============================================================================
void
CSO::on_signal_session_located ()
{
	on_signal_generic("on_ardour_session_located");
}

//=============================================================================
void
CSO::on_signal_session_exported (string path, string name)
{
	string fname="on_ardour_session_exported";
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref(path, name);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::on_signal_route_added (ARDOUR::RouteList &rl)
{
/*
	for (RouteList::const_iterator r = rl.begin(); r != rl.end(); ++r)
	{
		fprintf(stderr,"name: %s\n", (*r)->name().c_str());
	}
*/
	on_signal_generic("on_ardour_routes_added");
}

//=============================================================================
void
CSO::on_signal_route_group_property_changed (RouteGroup* rg)
{
	string fname="on_ardour_route_group_property_changed";
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref(); ///pass something from rg?
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::on_signal_dirty_state_changed ()
{
	on_signal_generic("on_ardour_dirty_state_changed");
}

//=============================================================================
void
CSO::on_signal_state_saved (string session_name)
{
	string fname="on_ardour_state_saved";
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref(session_name);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::on_signal_solo_state_changed (bool is_active)
{
	string fname="on_ardour_solo_state_changed";
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref(is_active);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::on_signal_config_parameter_changed (string param)
{
	string fname="on_ardour_config_parameter_changed";
	luabridge::LuaRef lua_ref = luabridge::getGlobal(L, fname.c_str());
	if(lua_ref.isFunction ())
	{
		lua_ref(param);
	}else{warn_lua_function_not_found(fname);}
}

//=============================================================================
void
CSO::on_signal_stripable_selection_changed ()
{
	on_signal_generic("on_ardour_stripable_selection_changed");
}

//=============================================================================
bool
CSO::cb_timer1 ()
{
	string fname="cso_timer1";
	luabridge::LuaRef lua_ref = luabridge::getGlobal (L, fname.c_str());
	if(lua_ref.isFunction())
	{
		lua_ref(timer1_interval_ms);
	}else{warn_lua_function_not_found(fname);}
	return true;
}

//EOF
