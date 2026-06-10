#
# baresip iOS + telephony
# Fork: https://github.com/ishumakov881/baresip-ios
#

BUILD_DIR	:= build
CONTRIB_DIR	:= contrib
DIST_DIR	:= dist

include mk/contrib.mk
include mk/telephony.mk

.PHONY: all download clean info

all: xcframework

download:
	rm -fr baresip re
	git clone --depth 1 https://github.com/baresip/baresip.git
	git clone --depth 1 https://github.com/baresip/re.git

clean:
	rm -rf $(BUILD_DIR) $(CONTRIB_DIR) $(DIST_DIR)
	rm -rf baresip re
