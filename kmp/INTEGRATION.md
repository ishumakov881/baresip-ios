# Подключение telephony.xcframework в KMP sip-модуль

## 1. Скачать xcframework

GitHub Actions artifact или Release этого репозитория.

```
prebuilt/ios/telephony.xcframework
```

## 2. build.gradle.kts

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

## 3. IosSipEngine

Скопировать `kmp/IosSipEngine.kt` в `iosMain`, подключить cinterop (`kmp/telephony.def`).

## 4. DI

`SipEngine` → реализация для iOS вместо заглушки.
