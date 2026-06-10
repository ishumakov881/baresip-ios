#ifndef LDS_TELEPHONY_H_
#define LDS_TELEPHONY_H_

#include "telephony_callback.h"

typedef int boolean_t;
enum {
	FALSE, TRUE
};

#define CMD_AUDIO_CALL  101
#define CMD_HANGUP      102
#define CMD_STOP        103

typedef struct AudioCall {
	char *host;
	int port;
	char *transport;
	char *account;
	char *user;
	char *passw;
	char *peer;
} AudioCall_t;

int telephony_init(const char *path);
int telephony_mainLoop(void);
void telephony_cmd(int cmd, void *data);

/** Удобная обёртка для Kotlin/Native (аналог JNI startAudioCall). */
void telephony_start_audio_call(
	const char *host, int port, const char *transport,
	const char *account, const char *login, const char *password, const char *peer);

void telephony_hangup(void);
void telephony_stop(void);

#endif
