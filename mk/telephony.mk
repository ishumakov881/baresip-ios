#
# Build libtelephony.a (objects) and libtelephony_all.a (merged with baresip) per slice.
#

TELEPHONY_DIR	:= $(SOURCE_PATH)/telephony
TELEPHONY_SRCS	:= $(TELEPHONY_DIR)/telephony.c $(TELEPHONY_DIR)/telephony_callback.c
TELEPHONY_OBJ_DEVICE := $(BUILD_DEVICE)/telephony/telephony.o $(BUILD_DEVICE)/telephony/telephony_callback.o
TELEPHONY_OBJ_SIM    := $(BUILD_SIM)/telephony/telephony.o $(BUILD_SIM)/telephony/telephony_callback.o

TELEPHONY_CFLAGS := -O2 -fPIC -DTARGET_OS_IPHONE=1 -DIPHONE \
	-I$(TELEPHONY_DIR) \
	-I$(BARESIP_PATH)/include \
	-I$(LIBRE_PATH)/include \
	-Wno-shorten-64-to-32 -Wno-cast-align

DIST_DIR	:= $(SOURCE_PATH)/dist
XCFRAMEWORK	:= $(DIST_DIR)/telephony.xcframework
MERGE_SCRIPT	:= $(SOURCE_PATH)/scripts/merge-static-lib.sh

.PHONY: telephony xcframework

telephony: baresip $(CONTRIB_DEVICE)/lib/libtelephony_all.a $(CONTRIB_SIM)/lib/libtelephony_all.a

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

$(CONTRIB_DEVICE)/lib/libtelephony_all.a: $(CONTRIB_DEVICE)/lib/libtelephony.a \
		$(CONTRIB_DEVICE)/lib/libbaresip.a \
		$(CONTRIB_DEVICE)/lib/libre.a
	bash $(MERGE_SCRIPT) $@ $(SDK_ARM) ios $(DEPLOYMENT_TARGET_VERSION) \
		$(BUILD_DEVICE)/baresip \
		$(CONTRIB_DEVICE)/lib/libtelephony.a \
		$(CONTRIB_DEVICE)/lib/libbaresip.a \
		$(CONTRIB_DEVICE)/lib/libre.a

$(CONTRIB_SIM)/lib/libtelephony_all.a: $(CONTRIB_SIM)/lib/libtelephony.a \
		$(CONTRIB_SIM)/lib/libbaresip.a \
		$(CONTRIB_SIM)/lib/libre.a
	bash $(MERGE_SCRIPT) $@ $(SDK_SIM) ios-simulator $(DEPLOYMENT_TARGET_VERSION) \
		$(BUILD_SIM)/baresip \
		$(CONTRIB_SIM)/lib/libtelephony.a \
		$(CONTRIB_SIM)/lib/libbaresip.a \
		$(CONTRIB_SIM)/lib/libre.a

xcframework: telephony
	@rm -rf $(XCFRAMEWORK)
	@mkdir -p $(DIST_DIR)/headers
	@cp $(TELEPHONY_DIR)/telephony.h $(TELEPHONY_DIR)/telephony_callback.h $(DIST_DIR)/headers/
	xcodebuild -create-xcframework \
		-library $(CONTRIB_DEVICE)/lib/libtelephony_all.a -headers $(DIST_DIR)/headers \
		-library $(CONTRIB_SIM)/lib/libtelephony_all.a -headers $(DIST_DIR)/headers \
		-output $(XCFRAMEWORK)
	@echo "Built $(XCFRAMEWORK)"
