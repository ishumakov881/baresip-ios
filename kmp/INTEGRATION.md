# Подключение telephony.xcframework в walhalla-kmp / ldsonline

## 1. Скачать xcframework

Из GitHub Actions artifact или Release: [ishumakov881/baresip-ios](https://github.com/ishumakov881/baresip-ios).

```
kmp/sip/prebuilt/ios/telephony.xcframework
```

## 2. build.gradle.kts (`:kmp:sip`)

```kotlin
kotlin {
    listOf(iosX64(), iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.compilations.getByName("main") {
            cinterops {
                val telephony by creating {
                    defFile(project.file("src/nativeInterop/cinterop/telephony.def"))
                    includeDirs(project.file("prebuilt/ios/Headers"))
                }
            }
        }
        target.binaries.framework {
            baseName = "sipKit"
            linkerOpts(
                "-F${project.file("prebuilt/ios")}",
                "-framework", "telephony",
                "-framework", "AudioToolbox",
                "-framework", "CoreAudio",
                "-framework", "AVFoundation",
                "-framework", "SystemConfiguration",
                "-framework", "CFNetwork",
            )
        }
    }
}
```

Скопировать `kmp/telephony.def` → `src/nativeInterop/cinterop/telephony.def`.

## 3. IosSipEngine

Скопировать `kmp/IosSipEngine.kt` в `src/iosMain/kotlin/net/lds/sip/`.

## 4. Koin

```kotlin
single<SipEngine> { IosSipEngine() }
```

вместо `StubSipEngine()`.
