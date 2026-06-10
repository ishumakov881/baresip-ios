# Подключение LdsTelephonyKit в walhalla-kmp / ldsonline

## 1. Скачать xcframework

Из GitHub Actions artifact или Release репозитория [ishumakov881/baresip-ios](https://github.com/ishumakov881/baresip-ios).

```
kmp/sip/prebuilt/ios/LdsTelephonyKit.xcframework
```

## 2. build.gradle.kts (`:kmp:sip`)

```kotlin
kotlin {
    listOf(iosX64(), iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.compilations.getByName("main") {
            cinterops {
                val ldsTelephony by creating {
                    defFile(project.file("src/nativeInterop/cinterop/telephony.def"))
                    includeDirs(project.file("prebuilt/ios/Headers"))
                }
            }
        }
        target.binaries.framework {
            baseName = "sipKit"
            linkerOpts(
                "-F${project.file("prebuilt/ios")}",
                "-framework", "LdsTelephonyKit",
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

Скопировать `kmp/IosSipEngine.kt` в `src/iosMain/kotlin/net/lds/sip/`, доработать `allocAudioCall` (malloc + strdup через cinterop).

## 4. Koin

```kotlin
single<SipEngine> { IosSipEngine() }
```

вместо `StubSipEngine()`.
