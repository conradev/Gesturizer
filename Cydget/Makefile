include theos/makefiles/common.mk

BUNDLE_NAME = GesturizerLockScreen
GesturizerLockScreen_FILES = GRLockScreenController.m GRLockScreenView.m
GesturizerLockScreen_LDFLAGS = -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.0.sdk/usr/lib/gcc/arm-apple-darwin10/4.2.1/
GesturizerLockScreen_CFLAGS = -I../Tweak/
GesturizerLockScreen_FRAMEWORKS = UIKit
GesturizerLockScreen_PRIVATE_FRAMEWORKS = SpringBoardUI
GesturizerLockScreen_INSTALL_PATH = /System/Library/SpringBoardPlugins/

include $(THEOS_MAKE_PATH)/bundle.mk
