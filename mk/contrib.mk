#
# upstream baresip-ios contrib.mk — arm64 device + x86_64 simulator, без armv7
#

DEPLOYMENT_TARGET_VERSION ?= 13.0

SOURCE_PATH	:= $(shell pwd)
LIBRE_PATH	:= $(SOURCE_PATH)/re
LIBREM_PATH	:= $(SOURCE_PATH)/rem
BARESIP_PATH	:= $(SOURCE_PATH)/baresip

SDK_ARM		:= $(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_SIM		:= $(shell xcrun --sdk iphonesimulator --show-sdk-path)
CC_ARM		:= xcrun --sdk iphoneos clang
CC_SIM		:= xcrun --sdk iphonesimulator clang

CONTRIB_DIR	:= $(SOURCE_PATH)/contrib
CONTRIB_AARCH64	:= $(CONTRIB_DIR)/aarch64
CONTRIB_X86_64	:= $(CONTRIB_DIR)/x86_64
CONTRIB_FAT	:= $(CONTRIB_DIR)/fat

BUILD_DIR	:= $(SOURCE_PATH)/build
BUILD_AARCH64	:= $(BUILD_DIR)/aarch64
BUILD_X86_64	:= $(BUILD_DIR)/x86_64

ARMROOT		:= $(SDK_ARM)/usr
ARMROOT_ALT	:= $(CONTRIB_FAT)
SIMROOT		:= $(SDK_SIM)/usr
SIMROOT_ALT	:= $(CONTRIB_FAT)

EXTRA_AARCH64 := \
	EXTRA_CFLAGS='-arch arm64 \
	-I$(CONTRIB_AARCH64)/include \
	-I$(CONTRIB_AARCH64)/include/rem \
	-Wno-cast-align -Wno-shorten-64-to-32 \
	-Wno-aggregate-return \
	-miphoneos-version-min=$(DEPLOYMENT_TARGET_VERSION) \
	-isysroot $(SDK_ARM) -DHAVE_AARCH64' \
	EXTRA_LFLAGS='-arch arm64 -mcpu=generic -marm \
	-L$(CONTRIB_FAT)/lib -isysroot $(SDK_ARM)' \
	OS=darwin ARCH=arm64 HAVE_ARM64=1

EXTRA_X86_64 := \
	EXTRA_CFLAGS='-D__DARWIN_ONLY_UNIX_CONFORMANCE \
	-mios-simulator-version-min=$(DEPLOYMENT_TARGET_VERSION) \
	-Wno-cast-align -Wno-shorten-64-to-32 \
	-Wno-aggregate-return \
	-arch x86_64 \
	-isysroot $(SDK_SIM) \
	-I$(CONTRIB_X86_64)/include \
	-I$(CONTRIB_X86_64)/include/rem' \
	OBJCFLAGS='-fobjc-abi-version=2 -fobjc-legacy-dispatch' \
	EXTRA_LFLAGS='-mios-simulator-version-min=$(DEPLOYMENT_TARGET_VERSION) -arch x86_64 \
	-L$(CONTRIB_FAT)/lib -isysroot $(SDK_SIM)'

.PHONY: contrib baresip libre librem info

contrib: baresip

$(BUILD_AARCH64) $(BUILD_X86_64):
	@mkdir -p $@

$(CONTRIB_FAT)/lib $(CONTRIB_AARCH64)/lib $(CONTRIB_X86_64)/lib:
	@mkdir -p $@

LIBRE_BUILD_FLAGS := USE_OPENSSL= OPENSSL_OPT= USE_ZLIB= OPT_SPEED=1 USE_APPLE_COMMONCRYPTO=1
LIBREM_BUILD_FLAGS := OPENSSL_OPT= OPT_SPEED=1
BARESIP_BUILD_FLAGS := STATIC=1 OPT_SPEED=1 USE_OPENSSL= USE_ZLIB= MOD_AUTODETECT= USE_FFMPEG=
BARESIP_MODULES := EXTRA_MODULES='g711 audiounit avcapture'

libre: $(CONTRIB_FAT)/lib
	@rm -f $(LIBRE_PATH)/libre.*
	@$(MAKE) -sC $(LIBRE_PATH) CC='$(CC_ARM)' \
		BUILD=$(BUILD_AARCH64)/libre \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(ARMROOT_ALT) \
		$(LIBRE_BUILD_FLAGS) $(EXTRA_AARCH64) \
		PREFIX= DESTDIR=$(CONTRIB_AARCH64) all install
	@rm -f $(LIBRE_PATH)/libre.*
	@$(MAKE) -sC $(LIBRE_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_X86_64)/libre \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(SIMROOT_ALT) \
		$(LIBRE_BUILD_FLAGS) $(EXTRA_X86_64) \
		PREFIX= DESTDIR=$(CONTRIB_X86_64) all install
	@lipo -arch x86_64 $(CONTRIB_X86_64)/lib/libre.a \
		-arch arm64 $(CONTRIB_AARCH64)/lib/libre.a \
		-create -output $(CONTRIB_FAT)/lib/libre.a

librem: libre
	@rm -f $(LIBREM_PATH)/librem.*
	@$(MAKE) -sC $(LIBREM_PATH) CC='$(CC_ARM)' \
		BUILD=$(BUILD_AARCH64)/librem \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(ARMROOT_ALT) \
		$(LIBREM_BUILD_FLAGS) $(EXTRA_AARCH64) \
		PREFIX= DESTDIR=$(CONTRIB_AARCH64) all install
	@rm -f $(LIBREM_PATH)/librem.*
	@$(MAKE) -sC $(LIBREM_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_X86_64)/librem \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(SIMROOT_ALT) \
		$(LIBREM_BUILD_FLAGS) $(EXTRA_X86_64) \
		PREFIX= DESTDIR=$(CONTRIB_X86_64) all install
	@lipo -arch x86_64 $(CONTRIB_X86_64)/lib/librem.a \
		-arch arm64 $(CONTRIB_AARCH64)/lib/librem.a \
		-create -output $(CONTRIB_FAT)/lib/librem.a

baresip: librem
	@rm -f $(BARESIP_PATH)/src/static.c $(BARESIP_PATH)/libbaresip.*
	@$(MAKE) -sC $(BARESIP_PATH) CC='$(CC_ARM)' \
		BUILD=$(BUILD_AARCH64)/baresip \
		SYSROOT=$(ARMROOT) SYSROOT_ALT=$(ARMROOT_ALT) \
		$(BARESIP_BUILD_FLAGS) $(BARESIP_MODULES) $(EXTRA_AARCH64) \
		PREFIX= DESTDIR=$(CONTRIB_AARCH64) install-static
	@rm -f $(BARESIP_PATH)/src/static.c $(BARESIP_PATH)/libbaresip.*
	@$(MAKE) -sC $(BARESIP_PATH) CC='$(CC_SIM)' \
		BUILD=$(BUILD_X86_64)/baresip \
		SYSROOT=$(SIMROOT) SYSROOT_ALT=$(SIMROOT_ALT) \
		$(BARESIP_BUILD_FLAGS) $(BARESIP_MODULES) $(EXTRA_X86_64) \
		PREFIX= DESTDIR=$(CONTRIB_X86_64) install-static
	@lipo -arch x86_64 $(CONTRIB_X86_64)/lib/libbaresip.a \
		-arch arm64 $(CONTRIB_AARCH64)/lib/libbaresip.a \
		-create -output $(CONTRIB_FAT)/lib/libbaresip.a

# aliases for optional mk/telephony.mk
CONTRIB_DEVICE	:= $(CONTRIB_AARCH64)
CONTRIB_SIM	:= $(CONTRIB_X86_64)
BUILD_DEVICE	:= $(BUILD_AARCH64)
BUILD_SIM	:= $(BUILD_X86_64)
CC_DEVICE	:= $(CC_ARM)

info:
	@echo "SDK_ARM: $(SDK_ARM)"
	@echo "SDK_SIM: $(SDK_SIM)"
