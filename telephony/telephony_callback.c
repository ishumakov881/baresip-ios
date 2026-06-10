#include <stddef.h>

#include "telephony_callback.h"

static telephony_event_handler_t g_handler;
static void *g_userdata;

void telephony_set_event_handler(telephony_event_handler_t handler, void *userdata)
{
	g_handler = handler;
	g_userdata = userdata;
}

void telephony_reset_callbacks(void)
{
	g_handler = NULL;
	g_userdata = NULL;
}

void notifyEvent(int event, int scode, const char *callId)
{
	if (g_handler)
		g_handler(event, scode, callId, g_userdata);
}
