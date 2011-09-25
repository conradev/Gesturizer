include theos/makefiles/common.mk

TWEAK_NAME = Gesturizer
Gesturizer_FILES = GRWindow.m GRGestureController.mm GRGestureRecognizer.m GRGestureRecognitionFunctions.m GRPaintView.m Tweak.xm
Gesturizer_LDFLAGS = -lactivator -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.0.sdk/usr/lib/gcc/arm-apple-darwin10/4.2.1/
Gesturizer_FRAMEWORKS = UIKit QuartzCore CoreGraphics
Gesturizer_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
