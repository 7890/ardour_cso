/*
 * Copyright (C) 2006-2009 Paul Davis
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

#ifndef ardour_cso_h
#define ardour_cso_h

#include <string>
#include <fstream>
#include <vector>
#include <pthread.h>
#include <lo/lo.h>

#define ABSTRACT_UI_EXPORTS
#include "pbd/abstract_ui.h"
#include "control_protocol/control_protocol.h"
#include "ardour/luaproc.h"
#include "LuaBridge/LuaBridge.h"
#include "ardour/luabindings.h"
#include "pbd/i18n.h"

//base64 lua functions
#include "cso_b64.h"
//cso.lua script encoded as base64
#include "cso_script.h"

namespace ARDOUR {
	class Session;
	class Route;
}

namespace ArdourSurface {

struct CSORequest : public BaseUI::BaseRequestObject
{
  public:
	CSORequest () {}
	~CSORequest() {}
};

class CSO : public ARDOUR::ControlProtocol, public AbstractUI<CSORequest>
{
  public:
	CSO (ARDOUR::Session&);
	virtual ~CSO();

	static CSO* instance() { return cso_instance; }

	XMLNode& get_state ();
	int set_state (const XMLNode&, int version);

	void stripable_selection_changed () {}///

	int set_active (bool yn);
	bool get_active () const;

	int start ();
	int stop ();

	static void* request_factory (uint32_t);
	//end of minimal set

	static float get_cso_api_version() { return cso_api_version; };

	//see tail of cso.h for more public methods
  protected:
	void thread_init ();
	void do_request (CSORequest*);
	bool osc_input_handler (Glib::IOCondition, lo_server);
	//end of minimal set

  private:
	static CSO* cso_instance;
	uint32_t osc_server_port;
	lo_server osc_server;
	//end of minimal set

	static constexpr float cso_api_version=0.2f; //~
	std::string cso_home_path;
	std::string cso_start_script_uri;
	std::string cso_custom_script_uri;

	bool osc_debug_enabled;
	bool lua_print_stderr_enabled;
	bool lua_print_osc_enabled;

	struct OSCMapping
	{
	  public:
		OSCMapping(std::string p, std::string t, std::string m)
		{
			path=p; types=t; method=m;
		}
		std::string path;
		std::string types;
		std::string method;
	};

	typedef std::map<std::string, OSCMapping*> OSCMap;
	typedef std::pair<std::string, OSCMapping*> OSCMapPair;
	OSCMap osc_map;

	void lua_push_lo_type(OSCMapping *mapping, lo_arg **argv, uint32_t argno);

	static std::string set_bool_from_int(bool *b, int i)
	{
		if(i==0)
		{
			*b=false;
			return "OFF";
		}
		else
		{
			*b=true;
			return "ON";
		}
	}

	static int int_from_argv_iTF (const char* types, lo_arg **argv, int argc)
	{
		if(argc<1) {return 0;}
		if(types[0]=='i')
		{
			if(argv[0]->i==1){return 1;}else{return 0;}
		}
		else if(types[0]=='T')
		{
			return 1;
		}
		else if(types[0]=='F')
		{
			return 0;
		}
		return 0;
	}

	static lo_address lo_address_from_argv_si (const char* types, lo_arg **argv, int argc)
	{
		if(argc!=2) {return 0;} ///

		if(strcmp (types, "si") == 0)
		{
			//int to char
			int port = argv[1]->i;
			std::ostringstream ostr;
			ostr << port;
			std::string port_s = ostr.str(); //the str() function of the stream
			return lo_address_new(&argv[0]->s, port_s.c_str());
		}
		return 0;
	}

	//static method: _name
	//member method: cb_name (to be implemented in cso.cc)
#define CSO_STATIC_TO_MEMBER_CB_PAIR(name) \
	static int _ ## name (const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data) { \
		return ((CSO*)user_data)->cb_ ## name (path, types, argv, argc, data); \
	} \
	int cb_ ## name (const char *path, const char *types, lo_arg **argv, int argc, void *data);

	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_catchall);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_eval);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_map_add);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_map_remove);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_map_clear);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_map_dump);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_connect);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_debug);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_print);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_print_osc);
	CSO_STATIC_TO_MEMBER_CB_PAIR(osc_print_osc_address);

	LuaState lua;
	lua_State* L;
	bool set_script_uri_and_path ();
	void lua_init ();
	void lua_print (std::string s);
	void warn_lua_function_not_found (std::string function_name);

	void register_osc_callbacks ();
	void register_signal_callbacks ();

	lo_address feedback_address;
	void set_feedback_address (lo_address addr);

	lo_address print_address;
	void set_print_address (lo_address addr);

	uint32_t timer1_interval_ms;

	bool cb_timer1 (void);
	sigc::connection periodic_connection;
	PBD::ScopedConnectionList session_connections;

	//signals emitted by ardour
	//!\ this list is not complete
	bool on_signal_generic (std::string lua_function_name);
	void on_signal_transport_state_changed ();
	void on_signal_record_state_changed ();
	void on_signal_session_exported (std::string path, std::string name);
	void on_signal_route_added (ARDOUR::RouteList &rl);
	void on_signal_route_group_property_changed(ARDOUR::RouteGroup* rg);
	void on_signal_dirty_state_changed ();
	void on_signal_state_saved (std::string s);
	void on_signal_solo_state_changed (bool is_active);
	void on_signal_config_parameter_changed (std::string param);
	void on_signal_looped ();
	void on_signal_session_located ();
	void on_signal_stripable_selection_changed ();

  public:
	//based on hexdump() in libs/ptformat/ptfformat.cc
	static void hexdump(uint8_t *data, int len)
	{
		int i,j,k,end,step=16;

		for (i = 0; i < len; i += step) {
			printf("0x%02X: ", i);
			end = i + step;
			if (end > len) end = len;
			for (j = i; j < end; j++) {
				//omit 0x prefix
				printf("%02X ", data[j]);
			}
			if(j % step != 0) //align plain text output
			{
				int diff = (step - (j % step)) *3; //*3: 'FF '
				for(k = 0; k < diff; k++) {
					printf(" ");
				}
			}
			for (j = i; j < end; j++) {
				if (data[j] < 128 && data[j] > 32)
					printf("%c", data[j]);
				else
					printf(".");
			}
			printf("\n");
		}
	} //hexdump()

	//based on debugmsg in libs/surfaces/osc/osc.cc
	static void debugmsg (const char *prefix, const char *path, const char* types, lo_arg **argv, int argc, lo_message msg)
	{
		std::stringstream ss;
		for (int i = 0; i < argc; ++i) {
			lo_type type = (lo_type)types[i];
				ss << "  ";
			switch (type) {
				case LO_INT32:
					ss << "i=" << argv[i]->i<< "\n";
					break;
				case LO_FLOAT:
					ss << "f=" << argv[i]->f<< "\n";
					break;
				case LO_DOUBLE:
					ss << "d=" << argv[i]->d<< "\n";
					break;
				case LO_STRING:
					ss << "s=" << &argv[i]->s<< "\n";
					break;
				case LO_INT64:
					ss << "h=" << argv[i]->h<< "\n";
					break;
				case LO_CHAR:
					ss << "c=" << argv[i]->s<< "\n";
					break;
				case LO_TIMETAG:
					ss << "<Timetag>"<< "\n";
					break;
				case LO_BLOB:
					ss << "<BLOB>"<< "\n";
					break;
				case LO_TRUE:
					ss << "#T"<< "\n";
					break;
				case LO_FALSE:
					ss << "#F"<< "\n";
					break;
				case LO_NIL:
					ss << "NIL"<< "\n";
					break;
				case LO_INFINITUM:
					ss << "#inf"<< "\n";
					break;
				case LO_MIDI:
					ss << "<MIDI>"<< "\n";
					break;
				case LO_SYMBOL:
					ss << "<SYMBOL>"<< "\n";
					break;
				default:
					ss << "< ?? >"<< "\n";
					break;
			}
		}

		lo_address addr=lo_message_get_source(msg);
		std::cout << prefix << ": " << lo_address_get_hostname(addr) << ":" << lo_address_get_port(addr) << " " << path << "\n" << ss.str();
	}// debugmsg()

  }; //class CSO
} // namespace ArdourSurface

#endif // ardour_cso_h

//EOF
