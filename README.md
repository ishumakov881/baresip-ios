# Baresip for iOS

Как [upstream baresip-ios](https://github.com/baresip/baresip-ios):

```bash
make download
make contrib
```

Результат: `contrib/ios-arm64/lib/libre.a`, `libbaresip.a` и то же для `ios-simulator-arm64`.

Опционально (не CI): `make telephony` / `make xcframework` — обёртка `telephony/` для KMP.

## CI

- **GitHub Actions** — `.github/workflows/build-ios.yml`
- **GitLab CI** — `.gitlab-ci.yml` (нужен macOS runner `saas-macos-medium-m1`)

## KMP

[`kmp/INTEGRATION.md`](kmp/INTEGRATION.md)
