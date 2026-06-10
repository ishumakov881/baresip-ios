#!/usr/bin/env bash
#
# Merge static libraries for one iOS slice (device or simulator).
# libtool -static collides on duplicate .o basenames (reply.c.o, g711.c.o, …).
#
set -euo pipefail

if [[ $# -lt 6 ]]; then
	echo "Usage: $0 <out.a> <sdk> <platform> <min-version> <baresip-build-dir> <lib.a> ..." >&2
	exit 1
fi

OUT_A="$1"
SDK="$2"
PLATFORM="$3"
MIN_VER="$4"
BARESIP_BUILD="$5"
shift 5

MERGED_O="${OUT_A%.a}.o"
rm -f "$MERGED_O" "$OUT_A"

args=()
for lib in "$@"; do
	args+=(-force_load "$lib")
done

if [[ -d "$BARESIP_BUILD/modules" ]]; then
	for lib in "$BARESIP_BUILD"/modules/*/*.a; do
		[[ -f "$lib" ]] || continue
		args+=(-force_load "$lib")
	done
fi

ld -r -arch arm64 -isysroot "$SDK" \
	-platform_version "$PLATFORM" "$MIN_VER" "$MIN_VER" \
	-o "$MERGED_O" \
	"${args[@]}"

ar rcs "$OUT_A" "$MERGED_O"
rm -f "$MERGED_O"

echo "Merged $(basename "$OUT_A") for $PLATFORM"
