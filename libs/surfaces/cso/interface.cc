/*
 * Copyright (C) 2009 Paul Davis
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
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *   
 */

#include "ardour/rc_configuration.h"
#include "control_protocol/control_protocol.h"
#include "cso.h"

using namespace ARDOUR;
using namespace ArdourSurface;

static ControlProtocol*
new_cso_protocol (ControlProtocolDescriptor* /*descriptor*/, Session* s)
{
	///CSO* cso = new CSO (*s, Config->get_osc_port());
	CSO* cso = new CSO (*s);
	///cso->set_active (true);
	return cso;
}

static void
delete_cso_protocol (ControlProtocolDescriptor* /*descriptor*/, ControlProtocol* cp)
{
	delete cp;
}

static bool
probe_cso_protocol (ControlProtocolDescriptor* /*descriptor*/)
{
	///
	return true;
}

static void*
cso_request_buffer_factory (uint32_t num_requests)
{
	return CSO::request_factory (num_requests);
}

static ControlProtocolDescriptor cso_descriptor = {
	/*name :              */   "Control Surface Object (CSO)",
	/*id :                */   "uri://ardour.org/surfaces/cso:0",
	/*ptr :               */   0,
	/*module :            */   0,
	/*mandatory :         */   0,
	/*supports_feedback : */   true,
	/*probe :             */   probe_cso_protocol,
	/*initialize :        */   new_cso_protocol,
	/*destroy :           */   delete_cso_protocol,
	/*request_buffer_factory */ cso_request_buffer_factory
};

extern "C" ARDOURSURFACE_API ControlProtocolDescriptor* protocol_descriptor () { return &cso_descriptor; }

//EOF
