#import "GRGestureDetailListController.h"
#import "GRConfigureActivatorController.h"

#import <libactivator/libactivator.h>

@implementation GRGestureDetailListController

@synthesize gesture=_gesture;

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *mutSpecs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"GestureDetailListController" target:self]];

        for (PSSpecifier *spec in mutSpecs) {
            NSString *specID = [[spec properties] objectForKey:@"id"];
	        if ([specID isEqualToString:@"url"]) {
		        _urlField = [spec retain];
            } else if ([specID isEqualToString:@"configureActivator"]) {
                _activatorConfigure = [spec retain];
            } else if ([specID isEqualToString:@"recordGesture"]) {
                _recordGesture = [spec retain];
            } else if ([specID isEqualToString:@"changeGesture"]) {
                _changeGesture = [spec retain];
            } else if ([specID isEqualToString:@"deleteButton"]) {
                [spec setProperty:self forKey:@"target"];
            }
        }

        if (![self.gesture objectForKey:@"strokes"]) {
            [mutSpecs removeObject:_changeGesture];
        } else {
            [mutSpecs removeObject:_recordGesture];
        }

        NSString *action = [self.gesture objectForKey:@"action"];
        if ([action isEqualToString:@"activator"]) {
            [mutSpecs removeObject:_urlField];
        } else if ([action isEqualToString:@"url"]) {
            [mutSpecs removeObject:_activatorConfigure];
        }

        _specifiers = [mutSpecs copy];
    }

    return _specifiers;
}

- (void)dealloc {
    self.gesture = nil;

    [super dealloc];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    NSString *gesture = [specifier propertyForKey:@"gesture"];
    if (gesture) {
        self.gesture = gesture;
    } else {
        CFUUIDRef uuid =  CFUUIDCreate(NULL);
        NSString *gestureID = [(NSString *)CFUUIDCreateString(NULL, uuid) autorelease];
        CFRelease(uuid);

        NSMutableDictionary *gestureDict = [NSMutableDictionary dictionary];
        [gestureDict setObject:@"" forKey:@"name"];
        [gestureDict setObject:@"" forKey:@"url"];
        [gestureDict setObject:@"activator" forKey:@"action"];
        [gestureDict setObject:gestureID forKey:@"id"];
        self.gesture = gestureDict;

        [self saveChanges];
    }

	[super setSpecifier:specifier];
}

- (void)setNameValue:(NSString *)value specifier:(PSSpecifier *)spec {
    [self.gesture setObject:value forKey:@"name"];
    [self saveChanges];
}

- (NSString *)getNameValue:(PSSpecifier *)spec {
    return [self.gesture objectForKey:@"name"];
}

- (void)setURLValue:(NSString *)value specifier:(PSSpecifier *)spec {
    [self.gesture setObject:value forKey:@"url"];
    [self saveChanges];
}

- (NSString *)getURLValue:(PSSpecifier *)spec {
    return [self.gesture objectForKey:@"url"];
}

- (void)setActionValue:(NSString *)value specifier:(PSSpecifier *)spec {
    [self.gesture setObject:value forKey:@"action"];
    [self saveChanges];

    if ([value isEqualToString:@"activator"]) {
        if ([[self specifiers] containsObject:_urlField]) {
            [self removeSpecifier:_urlField];
        }
        if (![[self specifiers] containsObject:_activatorConfigure]) {
            [self insertSpecifier:_activatorConfigure afterSpecifierID:@"action"];
        }
    } else if ([value isEqualToString:@"url"]) {
        if ([[self specifiers] containsObject:_activatorConfigure]) {
            [self removeSpecifier:_activatorConfigure];
        }
        if (![[self specifiers] containsObject:_urlField]) {
            [self insertSpecifier:_urlField afterSpecifierID:@"action"];
        }
    }
}

- (NSString *)getActionValue:(PSSpecifier *)spec {
    return [self.gesture objectForKey:@"action"];
}

- (void)recordGesture:(PSSpecifier *)spec {
    for (UITableCell *cell in [_cells allValues]) {
        if ([cell respondsToSelector:@selector(resignFirstResponder)]) {
            [cell resignFirstResponder];
        }
    }

    GRGestureRecordingViewController *gestureRecorder = [[GRGestureRecordingViewController alloc] initWithDelegate:self];
    gestureRecorder.wantsFullScreenLayout = YES;
    gestureRecorder.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:gestureRecorder animated:YES];
}

- (void)gestureWasRecorded:(NSArray *)strokes {
    [self.gesture setObject:strokes forKey:@"strokes"];
    [self.gesture removeObjectForKey:@"templates"];
    [self saveChanges];

    if ([[self specifiers] containsObject:_recordGesture]) {
        [self removeSpecifier:_recordGesture];
    }
    if (![[self specifiers] containsObject:_changeGesture]) {
        [self insertSpecifier:_changeGesture afterSpecifierID:@"recordGroup"];
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (void)confirmDelete {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIAlertView *confirmAlert = [[UIAlertView alloc] initWithTitle:@"Delete Gesture" message:@"Are you sure you want to delete this gesture?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
        [confirmAlert show];
        [confirmAlert release];
    } else {
        UIActionSheet *confirmSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Gesture" otherButtonTitles:nil];
        [confirmSheet showInView:self.view];
        [confirmSheet release];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.destructiveButtonIndex == buttonIndex) {
        [self deleteGesture];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.firstOtherButtonIndex == buttonIndex) {
        [self deleteGesture];
    }
}

- (void)deleteGesture {
    [[GRRootListController sharedInstance] deleteGesture:self.gesture];
    [self close];
}

- (void)configureActivator:(PSSpecifier *)spec {
    NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [self.gesture objectForKey:@"id"]];
    GRConfigureActivatorController *activatorConfigurer = [[GRConfigureActivatorController alloc] initWithEventName:eventName];
    [self pushController:activatorConfigurer];
}

- (void)saveChanges {
    [[GRRootListController sharedInstance] updateGesture:self.gesture];
}

- (void)close {
    [[self rootController] popViewControllerAnimated:YES];
}

@end
