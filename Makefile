include theos/makefiles/common.mk

SUBPROJECTS = Tweak PreferenceBundle Cydget

include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -iname '*.plist' -exec plutil -convert binary1 {} \;$(ECHO_END)
