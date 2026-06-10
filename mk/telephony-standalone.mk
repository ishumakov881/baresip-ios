#
# Опционально: telephony.xcframework (сначала make contrib).
#

include $(dir $(lastword $(MAKEFILE_LIST)))contrib.mk
include $(dir $(lastword $(MAKEFILE_LIST)))telephony.mk
