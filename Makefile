################################
# Main Makefile for Gesturizer #
################################

SUBPROJECTS = Tweak PreferenceBundle

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -iname '*.plist' -exec plutil -convert binary1 {} \;$(ECHO_END)

cleaner : clean
	$(ECHO_NOTHING)echo 'Making cleaner...'$(ECHO_END)
	rm -rf *.deb
	install.exec 'rm -rf *.deb'

run : package install

runs : package installs
