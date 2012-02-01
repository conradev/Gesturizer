include theos/makefiles/common.mk

BUNDLE_NAME = GesturizerSettings
GesturizerSettings_FILES = GRRootListController.m GRGestureDetailListController.m GRNewGestureListController.m GRNewGestureSetupController.m GRConfigureActivatorController.m GRPaintView.m GRGestureRecordingView.m GRGestureRecordingViewController.m GRDeleteButtonView.m GRWebSettingsController.m
GesturizerSettings_LDFLAGS = -lactivator
GesturizerSettings_INSTALL_PATH = /Library/PreferenceBundles
GesturizerSettings_FRAMEWORKS = UIKit CoreGraphics QuartzCore MessageUI
GesturizerSettings_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk
