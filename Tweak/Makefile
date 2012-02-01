include theos/makefiles/common.mk

TWEAK_NAME = Gesturizer
Gesturizer_FILES = GRWindow.m GRGestureController.mm GRGestureRecognizer.m GRGestureRecognitionFunctions.m GRPaintView.m Tweak.xm
Gesturizer_LDFLAGS = -lactivator
Gesturizer_FRAMEWORKS = UIKit QuartzCore CoreGraphics CFNetwork
Gesturizer_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
