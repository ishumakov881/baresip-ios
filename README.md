# Baresip for iOS + telephony

Fork [baresip/baresip-ios](https://github.com/baresip/baresip-ios) + слой **`telephony/`** (тот же сценарий, что на Android: `ua_register` → `ua_connect`).

Собирает **`telephony.xcframework`** для KMP (`:kmp:sip` / `io.github.ishumakov881:sip`).

## Локальная сборка (только macOS + Xcode)

```bash
make download
make all
# → dist/telephony.xcframework
```

## CI

GitHub Actions: [`.github/workflows/build-ios.yml`](.github/workflows/build-ios.yml)

- `push` / `workflow_dispatch` → artifact **telephony-xcframework**
- `release` → zip в assets

## API (C)

См. `telephony/telephony.h` — те же точки входа, что JNI на Android (`telephony_init`, `telephony_mainLoop`, `telephony_start_audio_call`, …).

События UA — коды из `baresip.h` / Android `SipEvent`.

## Подключение в KMP

1. Artifact / релиз → `kmp/sip/prebuilt/ios/telephony.xcframework`
2. cinterop на `telephony.h`, `telephony_callback.h`
3. `IosSipEngine` вместо `StubSipEngine`

Подробнее: [`kmp/INTEGRATION.md`](kmp/INTEGRATION.md).

## Структура

```
telephony/          — call logic (iOS)
mk/contrib.mk       — baresip + re + rem
mk/telephony.mk     — libtelephony_all.a + telephony.xcframework
```
