#
# baresip iOS — https://github.com/ishumakov881/baresip-ios
#

BARESIP_VER	:= v3.24.0
RE_VER		:= v3.24.0
REM_VER		:= v2.12.0

include mk/contrib.mk

.PHONY: all download clean info telephony xcframework

all: contrib

download:
	rm -fr baresip re rem
	git clone --depth 1 --branch $(BARESIP_VER) https://github.com/baresip/baresip.git
	git clone --depth 1 --branch $(RE_VER) https://github.com/baresip/re.git
	git clone --depth 1 --branch $(REM_VER) https://github.com/baresip/rem.git

clean:
	rm -rf build contrib dist
	rm -rf baresip re rem

telephony xcframework:
	$(MAKE) -f mk/telephony-standalone.mk $@
