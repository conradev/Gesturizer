#import "GRNewGestureListController.h"

@implementation GRNewGestureListController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self removeSpecifierID:@"deleteButton"];

    self.navigationItem.title = @"New Gesture";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveAndClose)] autorelease];
    self.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(deleteGesture)] autorelease];

    [self.navigationItem.rightBarButtonItem setEnabled:([self.gesture objectForKey:@"stroke"] != nil)];
}

- (void)gestureWasRecorded:(NSArray *)strokes {
    [super gestureWasRecorded:strokes];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
}

- (void)saveAndClose {
    [self saveChanges];
    [self close];
}

- (void)close {
    [[self rootController] dismissAnimated:YES];
}

@end
