#import "GRDeleteButtonView.h"

@interface UIButton (Private)
- (void)_setupTitleView;
@end

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
        _deleteButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_deleteButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [_deleteButton setBackgroundImage:pressedImage forState:UIControlStateHighlighted];
        [_deleteButton setTitle:@"Delete Gesture" forState:UIControlStateNormal];
        [_deleteButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

        [_deleteButton _setupTitleView];
        for (UIView *subview in [_deleteButton subviews]) {
            if ([subview isKindOfClass:[UILabel class]]) {
                UILabel *buttonLabel = (UILabel *)subview;
                buttonLabel.font = [UIFont boldSystemFontOfSize:buttonLabel.font.pointSize];
            }
        }

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

    float width;
    if (self.bounds.size.width == 467.0f)
        width = 405.0f;
    else if (self.bounds.size.width == 723.0f)
        width = 633.0f;
    else if (self.bounds.size.width == 320.0f)
        width = 302.0f;
    else if (self.bounds.size.width == 480.0f)
        width = 462.0f;
    [_deleteButton setFrame:CGRectMake(((self.frame.size.width - width) / 2), 0, width, 43)];

}

- (float)preferredHeightForWidth:(float)width {
    return 54;
}

@end
