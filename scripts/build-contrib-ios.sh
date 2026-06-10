#!/usr/bin/env bash
#
# Cross-compile libre + libbaresip (static) for iOS device and simulator.
# Modern baresip/re use CMake; legacy Makefile targets (all/install) no longer exist.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET_VERSION:-13.0}"
CONTRIB_DIR="$ROOT/contrib"
BUILD_DIR="$ROOT/build"
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

if [[ ! -d "$ROOT/re" || ! -d "$ROOT/baresip" ]]; then
	echo "Run 'make download' first (needs re/ and baresip/)." >&2
	exit 1
fi

build_re() {
	local name="$1"
	local sysroot="$2"
	local prefix="$CONTRIB_DIR/$name"
	local build="$BUILD_DIR/$name/re"

	mkdir -p "$prefix" "$build"

	cmake -S "$ROOT/re" -B "$build" \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_SYSROOT="$sysroot" \
		-DCMAKE_INSTALL_PREFIX="$prefix" \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DUSE_OPENSSL=OFF \
		-DLIBRE_BUILD_SHARED=OFF \
		-DLIBRE_BUILD_STATIC=ON \
		-DUSE_REM=ON

	cmake --build "$build" --target re -j"$NCPU"
	cmake --install "$build"

	if [[ ! -f "$prefix/lib/libre.a" ]]; then
		mkdir -p "$prefix/lib"
		cp "$build/libre.a" "$prefix/lib/libre.a"
	fi
}

build_baresip() {
	local name="$1"
	local sysroot="$2"
	local prefix="$CONTRIB_DIR/$name"
	local build="$BUILD_DIR/$name/baresip"

	mkdir -p "$prefix" "$build"

	cmake -S "$ROOT/baresip" -B "$build" \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_SYSROOT="$sysroot" \
		-DCMAKE_INSTALL_PREFIX="$prefix" \
		-DCMAKE_PREFIX_PATH="$prefix" \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DSTATIC=ON \
		-DMODULES="g711;audiounit;stun;turn;ice;uuid" \
		-DRE_INCLUDE_DIR="$prefix/include/re" \
		-DRE_LIBRARY="$prefix/lib/libre.a"

	cmake --build "$build" --target baresip -j"$NCPU"
	cmake --install "$build" --component Development

	if [[ ! -f "$prefix/lib/libbaresip.a" ]]; then
		mkdir -p "$prefix/lib"
		cp "$build/libbaresip.a" "$prefix/lib/libbaresip.a"
	fi
}

build_slice() {
	local name="$1"
	local sysroot="$2"

	echo "=== contrib: $name ==="
	build_re "$name" "$sysroot"
	build_baresip "$name" "$sysroot"
}

SDK_ARM="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_SIM="$(xcrun --sdk iphonesimulator --show-sdk-path)"

build_slice "ios-arm64" "$SDK_ARM"
build_slice "ios-simulator-arm64" "$SDK_SIM"

echo "Contrib build complete."
