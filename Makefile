#
# baresip iOS — fork https://github.com/ishumakov881/baresip-ios
#

BUILD_DIR	:= build
CONTRIB_DIR	:= contrib
DIST_DIR	:= dist

include mk/contrib.mk

.PHONY: all download clean info telephony xcframework

all: contrib

download:
	rm -fr baresip re
	git clone --depth 1 https://github.com/baresip/baresip.git
	git clone --depth 1 https://github.com/baresip/re.git

clean:
	rm -rf $(BUILD_DIR) $(CONTRIB_DIR) $(DIST_DIR)
	rm -f $(CONTRIB_DIR)/.contrib-built
	rm -rf baresip re

# опционально, не входит в `make all` / CI
telephony xcframework:
	$(MAKE) -f mk/telephony-standalone.mk $@
