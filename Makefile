#
# baresip iOS — https://github.com/ishumakov881/baresip-ios
#

BARESIP_VER	:= v4.8.0
RE_VER		:= v4.8.1

include mk/contrib.mk

.PHONY: all download clean info telephony xcframework

all: contrib xcframework

download:
	rm -fr baresip re
	git clone --depth 1 --branch $(BARESIP_VER) https://github.com/baresip/baresip.git
	git clone --depth 1 --branch $(RE_VER) https://github.com/baresip/re.git

clean:
	rm -rf build contrib dist
	rm -f contrib/.contrib-built
	rm -rf baresip re

telephony xcframework:
	$(MAKE) -f mk/telephony-standalone.mk $@
