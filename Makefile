TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VibeTendies
VibeTendies_FILES = Tweak.x
VibeTendies_CFLAGS = -fobjc-arc
VibeTendies_FRAMEWORKS = UIKit

SUBPROJECTS += VibeTendiesPrefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard Preferences"
