/**
 * LDS Online iOS telephony — same call flow as Android telephony.c:
 * ua_alloc → ua_register → ua_connect(peer).
 */
#include <stdlib.h>
#include <string.h>

#include <re.h>
#include <baresip.h>

#include "telephony.h"
#include "telephony_platform.h"

static const char *g_cfgBuf =
	"# Core\n"
	"poll_method\t\tkqueue\n"
	"\n"
	"# Call\n"
	"call_local_timeout\t120\n"
	"call_max_calls\t\t1\n"
	"\n"
	"# Audio\n"
	"audio_player\t\taudiounit,nil\n"
	"audio_source\t\taudiounit,nil\n"
	"audio_alert\t\taudiounit,nil\n"
	"audio_level\t\tno\n"
	"ausrc_format\t\ts16\n"
	"auplay_format\t\ts16\n"
	"auenc_format\t\ts16\n"
	"audec_format\t\ts16\n"
	"audio_buffer\t\t20-160\n"
	"\n"
	"# Network\n"
	"dns_fallback\t\t8.8.8.8:53\n"
	"\n"
	"# Static modules (baresip-ios STATIC=1)\n"
	"module\t\t\tg711\n"
	"module\t\t\taudiounit\n"
	"module\t\t\tstun\n"
	"module\t\t\tturn\n"
	"module\t\t\tice\n"
	"module_tmp\t\tuuid\n";

static struct mqueue *g_messageQueue;
static struct call *g_call;

static void cmd_hangup(void);
static int cmd_audioCall(AudioCall_t *ac);

static void platform_log_msg(uint32_t level, const char *msg)
{
	const char delims[] = "\n";
	char *cpy = strdup(msg);
	char *line;

	if (!cpy)
		return;

	line = strtok(cpy, delims);
	while (line) {
		if (level > 2)
			LOGE("%s", line);
		else if (level == 2)
			LOGW("%s", line);
		else if (level == 1)
			LOGI("%s", line);
		else
			LOGD("%s", line);
		line = strtok(NULL, delims);
	}
	free(cpy);
}

static struct log g_platformLog;

static void event_listener(struct ua *ua, enum ua_event ev,
			   struct call *call, const char *prm, void *arg)
{
	const char *callId = NULL;
	uint16_t scode = 0;

	(void)ua;
	(void)call;
	(void)prm;
	(void)arg;

	if (UA_EVENT_CALL_RINGING == ev)
		callId = call_id(g_call);

	if (UA_EVENT_CALL_CLOSED == ev) {
		scode = call_scode(g_call);
		LOGI("UA_EVENT_CALL_CLOSED (%u)", scode);
		g_call = NULL;
	}
	else {
		LOGI("UA_EVENT_%s", uag_event_str(ev));
	}

	notifyEvent((int)ev, (int)scode, callId);
}

static void mqueue_handler(int id, void *data, void *arg)
{
	(void)arg;

	switch (id) {
	case CMD_AUDIO_CALL:
		cmd_audioCall((AudioCall_t *)data);
		break;
	case CMD_HANGUP:
		cmd_hangup();
		break;
	case CMD_STOP:
		re_cancel();
		break;
	default:
		break;
	}
}

static void cmd_hangup(void)
{
	struct ua *ua = uag_current();

	if (!ua)
		return;

	ua_hangup(ua, g_call, 0, NULL);
	ua_unregister(ua);
}

static int cmd_audioCall(AudioCall_t *ac)
{
	char aor[256];
	struct ua *ua = NULL;
	int err;

	if (!ac)
		return EINVAL;

	snprintf(aor, sizeof(aor),
		 "\"%s\" <sip:%s@%s:%d;transport=%s>;auth_pass=%s;",
		 ac->account, ac->user, ac->host, ac->port, ac->transport, ac->passw);

	err = ua_alloc(&ua, aor);
	if (err) {
		LOGI("ERROR: ua_alloc %d", err);
		goto out;
	}

	err = ua_register(ua);
	if (err) {
		LOGI("ERROR: ua_register %d", err);
		goto out;
	}

	err = ua_connect(ua, &g_call, NULL, ac->peer, VIDMODE_OFF);
	if (err)
		LOGI("ERROR: ua_connect %d", err);

out:
	if (err && ua)
		mem_deref(ua);

	free(ac->peer);
	free(ac->passw);
	free(ac->user);
	free(ac->account);
	free(ac->transport);
	free(ac->host);
	free(ac);

	return err;
}

static void tel_done(void)
{
	g_call = NULL;

	if (g_messageQueue) {
		g_messageQueue = mem_deref(g_messageQueue);
		g_messageQueue = NULL;
	}

	uag_event_unregister(event_listener);
	ua_stop_all(true);
	ua_close();

	conf_close();
	baresip_close();
	mod_close();
	libre_close();

	dbg_close();
	log_unregister_handler(&g_platformLog);
	telephony_reset_callbacks();
}

int telephony_init(const char *path)
{
	struct config *config;
	int err;

	(void)path;

	memset(&g_platformLog, 0, sizeof(g_platformLog));
	g_platformLog.h = platform_log_msg;
	log_register_handler(&g_platformLog);
	log_enable_debug(true);
	dbg_init(DBG_DEBUG, DBG_TIME);

	err = libre_init();
	if (err) {
		LOGI("ERROR: libre_init %d", err);
		return err;
	}

	if (path)
		conf_path_set(path);

	config = conf_config();
	config->call.local_timeout = 2 * 60;
	config->call.max_calls = 1;
	config->avt.rtp_timeout = 2 * 60;

	err = conf_configure_buf((const uint8_t *)g_cfgBuf, strlen(g_cfgBuf));
	if (err) {
		LOGI("ERROR: conf_configure_buf %d", err);
		tel_done();
		return err;
	}

	err = baresip_init(config);
	if (err) {
		LOGI("ERROR: baresip_init %d", err);
		tel_done();
		return err;
	}

	mod_init();

	err = conf_modules();
	if (err) {
		LOGI("ERROR: conf_modules %d", err);
		tel_done();
		return err;
	}

	err = ua_init("LDS Online", true, true, false);
	if (err) {
		LOGI("ERROR: ua_init %d", err);
		tel_done();
		return err;
	}

	err = uag_event_register(event_listener, NULL);
	if (err) {
		LOGI("ERROR: uag_event_register %d", err);
		tel_done();
		return err;
	}

	err = mqueue_alloc(&g_messageQueue, mqueue_handler, NULL);
	if (err) {
		LOGI("ERROR: mqueue_alloc %d", err);
		tel_done();
		return err;
	}

	return 0;
}

int telephony_mainLoop(void)
{
	int err = re_main(NULL);

	tel_done();
	return err;
}

void telephony_cmd(int cmd, void *data)
{
	if (g_messageQueue)
		mqueue_push(g_messageQueue, cmd, data);
}

static char *telephony_strdup(const char *src)
{
	size_t len;
	char *dst;

	if (!src)
		return NULL;

	len = strlen(src);
	dst = malloc(len + 1);
	if (!dst)
		return NULL;

	memcpy(dst, src, len + 1);
	return dst;
}

void telephony_start_audio_call(
	const char *host, int port, const char *transport,
	const char *account, const char *login, const char *password, const char *peer)
{
	AudioCall_t *ac;

	if (!host || !transport || !account || !login || !password || !peer || port == 0)
		return;

	ac = calloc(1, sizeof(*ac));
	if (!ac)
		return;

	ac->host = telephony_strdup(host);
	ac->transport = telephony_strdup(transport);
	ac->account = telephony_strdup(account);
	ac->user = telephony_strdup(login);
	ac->passw = telephony_strdup(password);
	ac->peer = telephony_strdup(peer);
	ac->port = port;

	telephony_cmd(CMD_AUDIO_CALL, ac);
}

void telephony_hangup(void)
{
	telephony_cmd(CMD_HANGUP, NULL);
}

void telephony_stop(void)
{
	telephony_cmd(CMD_STOP, NULL);
}
