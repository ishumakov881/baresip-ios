#
# iOS contrib: libre + libbaresip (arm64 device + arm64 simulator) via CMake.
#

DEPLOYMENT_TARGET_VERSION ?= 13.0

SOURCE_PATH	:= $(shell pwd)
LIBRE_PATH	:= $(SOURCE_PATH)/re
BARESIP_PATH	:= $(SOURCE_PATH)/baresip

SDK_ARM		:= $(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_SIM		:= $(shell xcrun --sdk iphonesimulator --show-sdk-path)
CC_DEVICE	:= xcrun --sdk iphoneos clang
CC_SIM		:= xcrun --sdk iphonesimulator clang

CONTRIB_DIR	:= $(SOURCE_PATH)/contrib
CONTRIB_DEVICE	:= $(CONTRIB_DIR)/ios-arm64
CONTRIB_SIM	:= $(CONTRIB_DIR)/ios-simulator-arm64

BUILD_DIR	:= $(SOURCE_PATH)/build
BUILD_DEVICE	:= $(BUILD_DIR)/ios-arm64
BUILD_SIM	:= $(BUILD_DIR)/ios-simulator-arm64

CONTRIB_STAMP	:= $(CONTRIB_DIR)/.contrib-built

.PHONY: contrib baresip libre info

contrib: baresip

$(CONTRIB_STAMP):
	@DEPLOYMENT_TARGET_VERSION=$(DEPLOYMENT_TARGET_VERSION) bash scripts/build-contrib-ios.sh
	@test -f $(CONTRIB_DEVICE)/lib/libre.a
	@test -f $(CONTRIB_DEVICE)/lib/libbaresip.a
	@test -f $(CONTRIB_SIM)/lib/libre.a
	@test -f $(CONTRIB_SIM)/lib/libbaresip.a
	@touch $@

baresip libre: $(CONTRIB_STAMP)

$(CONTRIB_DEVICE)/lib/libre.a \
$(CONTRIB_DEVICE)/lib/libbaresip.a \
$(CONTRIB_SIM)/lib/libre.a \
$(CONTRIB_SIM)/lib/libbaresip.a: $(CONTRIB_STAMP)
	@test -f $@

info:
	@echo "SDK_ARM:    $(SDK_ARM)"
	@echo "SDK_SIM:    $(SDK_SIM)"
