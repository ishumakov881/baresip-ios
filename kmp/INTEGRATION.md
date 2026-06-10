# KMP `:kmp:sip`

## Артефакт CI

- `dist/telephony.xcframework` — cinterop на `telephony.h`
- `contrib/ios-arm64/lib/libre.a`, `libbaresip.a`
- `contrib/ios-simulator-arm64/lib/libre.a`, `libbaresip.a`

Склейка в один `.a` не нужна (upstream тоже линкует три библиотеки отдельно).

## prebuilt/

```
prebuilt/ios/
  telephony.xcframework
  device/libre.a libbaresip.a
  simulator/libre.a libbaresip.a
  Headers/   # telephony.h, telephony_callback.h
```

## linkerOpts (пример)

```kotlin
val slice = when (target.konanTarget.name) {
    "ios_arm64" -> "device"
    else -> "simulator"
}
linkerOpts(
    "-F${project.file("prebuilt/ios")}",
    "-framework", "telephony",
    "${project.file("prebuilt/ios/$slice")}/libbaresip.a",
    "${project.file("prebuilt/ios/$slice")}/libre.a",
    "-lresolv",
    "-framework", "AudioToolbox",
    "-framework", "AVFoundation",
    "-framework", "SystemConfiguration",
    "-framework", "CFNetwork",
    "-framework", "CoreMedia",
)
```

## Остальное

- `kmp/telephony.def`, `kmp/IosSipEngine.kt` → `iosMain`
- `SipEngine` в Koin вместо `StubSipEngine`
