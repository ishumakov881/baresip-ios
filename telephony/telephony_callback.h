#ifndef LDS_TELEPHONY_CALLBACK_H_
#define LDS_TELEPHONY_CALLBACK_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*telephony_event_handler_t)(int event, int scode, const char *call_id, void *userdata);

void telephony_set_event_handler(telephony_event_handler_t handler, void *userdata);
void telephony_reset_callbacks(void);
void notifyEvent(int event, int scode, const char *callId);

#ifdef __cplusplus
}
#endif

#endif
