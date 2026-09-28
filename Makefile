TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VibeTendies
VibeTendies_FILES = Tweak.x VibeTendiesController.x
VibeTendies_CFLAGS = -fobjc-arc
VibeTendies_FRAMEWORKS = UIKit UniformTypeIdentifiers

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
