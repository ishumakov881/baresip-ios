# LDS Telephony for iOS

Fork [baresip/baresip-ios](https://github.com/baresip/baresip-ios) + слой **`telephony/`** (тот же сценарий звонка, что на Android: `ua_register` → `ua_connect`).

Собирает **`LdsTelephonyKit.xcframework`** для KMP (`:kmp:sip` / `io.github.ishumakov881:sip`).

## Локальная сборка (только macOS + Xcode)

```bash
make download
make all
# → dist/LdsTelephonyKit.xcframework
```

## CI

GitHub Actions: [`.github/workflows/build-ios.yml`](.github/workflows/build-ios.yml)

- `push` / `workflow_dispatch` → artifact **LdsTelephonyKit-xcframework**
- `release` → прикрепляет xcframework к релизу

## API (C)

```c
#include "telephony.h"

typedef void (*telephony_event_handler_t)(int event, int scode, const char *call_id, void *userdata);

void telephony_set_event_handler(telephony_event_handler_t handler, void *userdata);
int telephony_init(const char *config_path);
int telephony_mainLoop(void);   // blocking — отдельный поток
void telephony_cmd(int cmd, void *data);
```

События UA — те же коды, что в Android `SipEvent` / `baresip.h` (`UA_EVENT_CALL_RINGING` = 10, и т.д.).

## Подключение в KMP

1. Скачать artifact / релиз → положить `LdsTelephonyKit.xcframework` в `kmp/sip/prebuilt/ios/`
2. `cinterop` на заголовки `telephony.h`, `telephony_callback.h`
3. `IosSipEngine` вместо `StubSipEngine`
4. Линковка frameworks: **AudioToolbox**, **CoreAudio**, **AVFoundation**, **SystemConfiguration**, **CFNetwork**, **libresolv**

## Структура

```
telephony/          — LDS call logic (iOS)
mk/contrib.mk       — baresip + re + rem (arm64 device + simulator)
mk/telephony.mk     — liblds-telephony.a + xcframework
dist/               — результат сборки (gitignore)
```

## Связь с Android

| Android (`:kmp:sip`) | iOS (этот репо) |
|----------------------|-----------------|
| `telephony.c` + OpenSLES | `telephony.c` + audiounit |
| JNI `wrapper.c` | `telephony_callback.c` → Kotlin cinterop |
| `AndroidSipEngine` | `IosSipEngine` |
