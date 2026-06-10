#ifndef TELEPHONY_PLATFORM_H_
#define TELEPHONY_PLATFORM_H_

#include <stdio.h>

#define LOGI(...) do { fprintf(stderr, "[telephony I] "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)
#define LOGW(...) do { fprintf(stderr, "[telephony W] "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)
#define LOGE(...) do { fprintf(stderr, "[telephony E] "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)
#define LOGD(...) do { fprintf(stderr, "[telephony D] "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)

#endif
