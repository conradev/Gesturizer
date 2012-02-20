include theos/makefiles/common.mk

BUNDLE_NAME = GesturizerLockScreen
GesturizerLockScreen_FILES = GRLockScreenController.m GRLockScreenView.m
GesturizerLockScreen_CFLAGS = -I../Tweak/ -I../Tweak/GoogleAnalytics/
GesturizerLockScreen_FRAMEWORKS = UIKit
GesturizerLockScreen_PRIVATE_FRAMEWORKS = SpringBoardUI
GesturizerLockScreen_INSTALL_PATH = /System/Library/SpringBoardPlugins/

include $(THEOS_MAKE_PATH)/bundle.mk
