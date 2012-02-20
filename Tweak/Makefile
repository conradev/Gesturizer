include theos/makefiles/common.mk

TWEAK_NAME = Gesturizer
Gesturizer_FILES = GRWindow.m GRGestureController.mm GRGestureRecognizer.m GRGestureRecognitionFunctions.m GRPaintView.m Tweak.xm
Gesturizer_OBJ_FILES = ./GoogleAnalytics/libGoogleAnalytics.a
Gesturizer_LDFLAGS = -lactivator -lsqlite3.0
Gesturizer_CFLAGS = -I./GoogleAnalytics/
Gesturizer_FRAMEWORKS = UIKit QuartzCore CoreGraphics CFNetwork
Gesturizer_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
