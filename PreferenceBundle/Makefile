include theos/makefiles/common.mk

BUNDLE_NAME = GesturizerSettings
GesturizerSettings_FILES = GRRootListController.m GRGestureDetailListController.m GRNewGestureListController.m GRNewGestureSetupController.m GRPressDetailListController.m GRConfigureActivatorController.m GRPaintView.m GRGestureRecordingView.m GRGestureRecordingViewController.m GRDeleteButtonView.m
GesturizerSettings_LDFLAGS = -lactivator -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.0.sdk/usr/lib/gcc/arm-apple-darwin10/4.2.1/
GesturizerSettings_INSTALL_PATH = /Library/PreferenceBundles
GesturizerSettings_FRAMEWORKS = UIKit OpenGLES CoreGraphics QuartzCore
GesturizerSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GesturizerSettings.plist$(ECHO_END)
