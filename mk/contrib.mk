#
# iOS contrib build (arm64 device + arm64 simulator).
# Uses CMake — upstream re/baresip no longer provide Makefile target `all`.
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

.PHONY: contrib baresip libre librem info

contrib: baresip

baresip libre librem:
	@DEPLOYMENT_TARGET_VERSION=$(DEPLOYMENT_TARGET_VERSION) bash scripts/build-contrib-ios.sh

info:
	@echo "SDK_ARM:    $(SDK_ARM)"
	@echo "SDK_SIM:    $(SDK_SIM)"
	@echo "CC_DEVICE:  $(CC_DEVICE)"
	@echo "CC_SIM:     $(CC_SIM)"
