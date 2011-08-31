#import "GRDeleteButtonView.h"

@implementation GRDeleteButtonView

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    if ((self = [self init])) {
        id target = [specifier propertyForKey:@"target"];
        SEL action = NSSelectorFromString([specifier propertyForKey:@"action"]);

        UIImage *buttonImage = _UIImageWithName(@"UIPreferencesDeleteButtonNormal.png");
        buttonImage = [buttonImage stretchableImageWithLeftCapWidth:floorf(buttonImage.size.width/2) topCapHeight:floorf(buttonImage.size.height/2)];
        UIImage *pressedImage = _UIImageWithName(@"UIPreferencesDeleteButtonPressed.png");
        pressedImage = [pressedImage stretchableImageWithLeftCapWidth:floorf(pressedImage.size.width/2) topCapHeight:floorf(pressedImage.size.height/2)];

        _deleteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [_deleteButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [_deleteButton setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
        [_deleteButton setTitle:@"Delete Gesture" forState:UIControlStateNormal];
        [_deleteButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:_deleteButton];
    }
    return self;
}

- (void)dealloc {
    [_deleteButton release];

    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [_deleteButton setFrame:CGRectMake(9, 0, self.frame.size.width - 18, 44)];

    [_deleteButton _setupTitleView];
    for (UIView *subview in [_deleteButton subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *buttonLabel = (UILabel *)subview;
            buttonLabel.font = [UIFont boldSystemFontOfSize:buttonLabel.font.pointSize];
        }
    }
}

- (float)preferredHeightForWidth:(float)arg1 {
    return 54;
}

@end
