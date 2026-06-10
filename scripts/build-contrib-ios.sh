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

# Upstream CMake still references OPENSSL_* when OpenSSL is absent (iOS uses Apple crypto).
# Tests also require OpenSSL — drop them for cross-compile.
prepare_sources() {
	local re_cmake="$ROOT/re/CMakeLists.txt"
	local baresip_cmake="$ROOT/baresip/CMakeLists.txt"

	rm -rf "$ROOT/re/test" "$ROOT/baresip/test" "$ROOT/baresip/webrtc"

	if grep -q '${OPENSSL_INCLUDE_DIR}' "$re_cmake"; then
		perl -pi -e 's/\$\{OPENSSL_INCLUDE_DIR\} //' "$re_cmake"
	fi
	if grep -q 'add_subdirectory(test' "$re_cmake"; then
		perl -pi -e 's/^add_subdirectory\(test.*\n//' "$re_cmake"
	fi

	if grep -q '${OPENSSL_INCLUDE_DIR}' "$baresip_cmake"; then
		perl -pi -e 's/\s*\$\{OPENSSL_INCLUDE_DIR\}//' "$baresip_cmake"
	fi
	if grep -q 'add_subdirectory(test' "$baresip_cmake"; then
		perl -pi -e 's/^add_subdirectory\(test\)\n//' "$baresip_cmake"
	fi
	if grep -q 'add_subdirectory(webrtc' "$baresip_cmake"; then
		perl -pi -e 's/^add_subdirectory\(webrtc\)\n//' "$baresip_cmake"
	fi
	# Static iOS lib only — baresip_exe triggers MACOSX_BUNDLE install rules.
	if grep -q '^add_executable(baresip_exe' "$baresip_cmake"; then
		perl -pi -e 's/^add_executable\(baresip_exe /# ios-static: add_executable(baresip_exe /' "$baresip_cmake"
		perl -pi -e 's/^set_target_properties\(baresip_exe /# ios-static: set_target_properties(baresip_exe /' "$baresip_cmake"
		perl -pi -e 's/^target_link_libraries\(baresip_exe /# ios-static: target_link_libraries(baresip_exe /' "$baresip_cmake"
	fi
	if grep -q 'install(TARGETS baresip_exe baresip' "$baresip_cmake"; then
		perl -pi -e 's/install\(TARGETS baresip_exe baresip/install(TARGETS baresip/' "$baresip_cmake"
	fi
	if grep -q 'add_subdirectory(packaging)' "$baresip_cmake"; then
		perl -pi -e 's/^ add_subdirectory\(packaging\)/# ios-static: add_subdirectory(packaging)/' "$baresip_cmake"
	fi
}

prepare_sources

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
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DSTATIC=ON \
		-DMODULES="g711;audiounit;stun;turn;ice;uuid" \
		-DRE_INCLUDE_DIR="$prefix/include/re" \
		-DRE_LIBRARY="$prefix/lib/libre.a" \
		-Dre_DIR="$prefix/lib/cmake/re"

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
