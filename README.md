# Baresip for iOS + telephony

```bash
make download
make all
```

- `contrib/ios-arm64/lib/` + `ios-simulator-arm64/lib/` — `libre.a`, `libbaresip.a`
- `dist/telephony.xcframework` — обёртка `telephony/` для KMP

Версии: baresip `v4.8.0`, re `v4.8.1`.

Только contrib (как upstream):

```bash
make download
make contrib
```

## CI

GitHub Actions / GitLab CI — `make download && make contrib && make xcframework`.

## KMP

[`kmp/INTEGRATION.md`](kmp/INTEGRATION.md)
