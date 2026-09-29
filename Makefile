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

# Конвертируем plist в бинарный прямо перед упаковкой
before-package::
	@echo "[VibeTendies] Converting plists to binary..."
	@find .theos/_ -name "*.plist" ! -name "Info.plist" | while read P; do \
		head -c 1 "$$P" | grep -q "{" && plistutil -i "$$P" -o "$$P.bin" -f bin && mv "$$P.bin" "$$P" || true; \
	done

after-install::
	install.exec "killall -9 SpringBoard Preferences"
