# Baresip for iOS + telephony

Fork [baresip/baresip-ios](https://github.com/baresip/baresip-ios) + слой **`telephony/`** (как JNI на Android).

## Сборка (macOS + Xcode)

```bash
make download
make all
```

Результат:
- `dist/telephony.xcframework` — только обёртка `telephony/*.c`
- `contrib/ios-arm64/lib/` и `contrib/ios-simulator-arm64/lib/` — `libre.a`, `libbaresip.a`

В KMP линкуете **все три** `.a` + системные фреймворки (как в [upstream README](https://github.com/baresip/baresip-ios): отдельные статические библиотеки, без склейки в один `.a`).

## Почему не «как в upstream в две строки»

| upstream | этот форк |
|----------|-----------|
| `make contrib` → fat `.a` под Xcode | то же + `telephony/` + xcframework для KMP |
| старые Makefile в re/rem/baresip | актуальный baresip 4.x — только CMake → `scripts/build-contrib-ios.sh` |

Снаружи команды те же: `make download` + `make all`.

## CI

GitHub Actions → artifact **telephony-ios** (xcframework + contrib libs).

## API

`telephony/telephony.h` — `telephony_init`, `telephony_mainLoop`, `telephony_start_audio_call`, …

## KMP

[`kmp/INTEGRATION.md`](kmp/INTEGRATION.md)
