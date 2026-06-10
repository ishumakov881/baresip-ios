#
# iOS contrib build (arm64 device + arm64 simulator).
# Based on baresip/baresip-ios, simplified for Xcode 15+ / GitHub Actions.
#

DEPLOYMENT_TARGET_VERSION ?= 13.0

SOURCE_PATH	:= $(shell pwd)
LIBRE_PATH	:= $(SOURCE_PATH)/re
LIBREM_PATH	:= $(SOURCE_PATH)/rem
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

ARMROOT		:= $(SDK_ARM)/usr
SIMROOT		:= $(SDK_SIM)/usr

EXTRA_DEVICE := \
	EXTRA_CFLAGS='-arch arm64 \
		-miphoneos-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		-isysroot $(SDK_ARM) \
		-I$(CONTRIB_DEVICE)/include \
		-Wno-shorten-64-to-32 -Wno-cast-align' \
	EXTRA_LFLAGS='-arch arm64 \
		-miphoneos-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		-isysroot $(SDK_ARM) \
		-L$(CONTRIB_DEVICE)/lib' \
	OS=darwin ARCH=arm64 HAVE_ARM64=1

EXTRA_SIM := \
	EXTRA_CFLAGS='-arch arm64 \
		-mios-simulator-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		-isysroot $(SDK_SIM) \
		-I$(CONTRIB_SIM)/include \
		-Wno-shorten-64-to-32 -Wno-cast-align' \
	EXTRA_LFLAGS='-arch arm64 \
		-mios-simulator-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		-isysroot $(SDK_SIM) \
		-L$(CONTRIB_SIM)/lib' \
	OS=darwin ARCH=arm64 HAVE_ARM64=1

LIBRE_BUILD_FLAGS := \
	USE_OPENSSL= OPENSSL_OPT= USE_ZLIB= OPT_SPEED=1 USE_APPLE_COMMONCRYPTO=1

LIBREM_BUILD_FLAGS := OPENSSL_OPT= OPT_SPEED=1

BARESIP_BUILD_FLAGS := \
	STATIC=1 OPT_SPEED=1 USE_OPENSSL= USE_ZLIB= MOD_AUTODETECT= USE_FFMPEG= \
	EXTRA_MODULES='g711 audiounit stun turn ice uuid'

.PHONY: contrib
contrib: baresip

$(BUILD_DEVICE) $(BUILD_SIM) $(CONTRIB_DEVICE)/lib $(CONTRIB_SIM)/lib:
	@mkdir -p $@

#
# libre
#

libre: $(CONTRIB_DEVICE)/lib $(CONTRIB_SIM)/lib
	@rm -f $(LIBRE_PATH)/libre.*
	@make -sC $(LIBRE_PATH) CC='$(CC_DEVICE)' \
		BUILD=$(BUILD_DEVICE)/libre \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(CONTRIB_DEVICE) \
		$(LIBRE_BUILD_FLAGS) $(EXTRA_DEVICE) \
		PREFIX= DESTDIR=$(CONTRIB_DEVICE) all install
	@rm -f $(LIBRE_PATH)/libre.*
	@make -sC $(LIBRE_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_SIM)/libre \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(CONTRIB_SIM) \
		$(LIBRE_BUILD_FLAGS) $(EXTRA_SIM) \
		PREFIX= DESTDIR=$(CONTRIB_SIM) all install

#
# librem
#

librem: libre
	@rm -f $(LIBREM_PATH)/librem.*
	@make -sC $(LIBREM_PATH) CC='$(CC_DEVICE)' \
		BUILD=$(BUILD_DEVICE)/librem \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(CONTRIB_DEVICE) \
		$(LIBREM_BUILD_FLAGS) $(EXTRA_DEVICE) \
		PREFIX= DESTDIR=$(CONTRIB_DEVICE) all install
	@rm -f $(LIBREM_PATH)/librem.*
	@make -sC $(LIBREM_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_SIM)/librem \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(CONTRIB_SIM) \
		$(LIBREM_BUILD_FLAGS) $(EXTRA_SIM) \
		PREFIX= DESTDIR=$(CONTRIB_SIM) all install

#
# baresip
#

baresip: librem
	@rm -f $(BARESIP_PATH)/src/static.c $(BARESIP_PATH)/libbaresip.*
	@make -sC $(BARESIP_PATH) CC='$(CC_DEVICE)' \
		BUILD=$(BUILD_DEVICE)/baresip \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(CONTRIB_DEVICE) \
		$(BARESIP_BUILD_FLAGS) $(EXTRA_DEVICE) \
		PREFIX= DESTDIR=$(CONTRIB_DEVICE) install-static
	@rm -f $(BARESIP_PATH)/src/static.c $(BARESIP_PATH)/libbaresip.*
	@make -sC $(BARESIP_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_SIM)/baresip \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(CONTRIB_SIM) \
		$(BARESIP_BUILD_FLAGS) $(EXTRA_SIM) \
		PREFIX= DESTDIR=$(CONTRIB_SIM) install-static

info:
	@echo "SDK_ARM:    $(SDK_ARM)"
	@echo "SDK_SIM:    $(SDK_SIM)"
	@echo "CC_DEVICE:  $(CC_DEVICE)"
	@echo "CC_SIM:     $(CC_SIM)"
