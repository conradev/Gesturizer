#import "GRPressDetailListController.h"

@implementation GRPressDetailListController

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PressDetailListController" target:self] retain];
  	}
	return _specifiers;
}

@end
