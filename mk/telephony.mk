#
# libtelephony.a per slice + telephony.xcframework (wrapper only).
# baresip/re link separately — same as upstream baresip-ios README.
#

TELEPHONY_DIR	:= $(SOURCE_PATH)/telephony
TELEPHONY_OBJ_DEVICE := $(BUILD_DEVICE)/telephony/telephony.o $(BUILD_DEVICE)/telephony/telephony_callback.o
TELEPHONY_OBJ_SIM    := $(BUILD_SIM)/telephony/telephony.o $(BUILD_SIM)/telephony/telephony_callback.o

TELEPHONY_CFLAGS := -O2 -fPIC -DTARGET_OS_IPHONE=1 -DIPHONE \
	-I$(TELEPHONY_DIR) \
	-I$(BARESIP_PATH)/include \
	-I$(LIBRE_PATH)/include \
	-Wno-shorten-64-to-32 -Wno-cast-align

DIST_DIR	:= $(SOURCE_PATH)/dist
XCFRAMEWORK	:= $(DIST_DIR)/telephony.xcframework

.PHONY: telephony xcframework

telephony: baresip $(CONTRIB_DEVICE)/lib/libtelephony.a $(CONTRIB_SIM)/lib/libtelephony.a

$(BUILD_DEVICE)/telephony $(BUILD_SIM)/telephony:
	@mkdir -p $@

$(BUILD_DEVICE)/telephony/%.o: $(TELEPHONY_DIR)/%.c | $(BUILD_DEVICE)/telephony
	$(CC_DEVICE) -arch arm64 -isysroot $(SDK_ARM) \
		-miphoneos-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		$(TELEPHONY_CFLAGS) -I$(CONTRIB_DEVICE)/include -c $< -o $@

$(BUILD_SIM)/telephony/%.o: $(TELEPHONY_DIR)/%.c | $(BUILD_SIM)/telephony
	$(CC_SIM) -arch arm64 -isysroot $(SDK_SIM) \
		-mios-simulator-version-min=$(DEPLOYMENT_TARGET_VERSION) \
		$(TELEPHONY_CFLAGS) -I$(CONTRIB_SIM)/include -c $< -o $@

$(CONTRIB_DEVICE)/lib/libtelephony.a: $(TELEPHONY_OBJ_DEVICE) | $(CONTRIB_DEVICE)/lib
	ar rcs $@ $(TELEPHONY_OBJ_DEVICE)

$(CONTRIB_SIM)/lib/libtelephony.a: $(TELEPHONY_OBJ_SIM) | $(CONTRIB_SIM)/lib
	ar rcs $@ $(TELEPHONY_OBJ_SIM)

xcframework: telephony
	@rm -rf $(XCFRAMEWORK)
	@mkdir -p $(DIST_DIR)/headers
	@cp $(TELEPHONY_DIR)/telephony.h $(TELEPHONY_DIR)/telephony_callback.h $(DIST_DIR)/headers/
	xcodebuild -create-xcframework \
		-library $(CONTRIB_DEVICE)/lib/libtelephony.a -headers $(DIST_DIR)/headers \
		-library $(CONTRIB_SIM)/lib/libtelephony.a -headers $(DIST_DIR)/headers \
		-output $(XCFRAMEWORK)
	@echo "Built $(XCFRAMEWORK)"
