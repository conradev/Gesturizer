#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

@interface GRDeleteButtonView : UIView {
    UIButton *_deleteButton;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier;
- (void)dealloc;
- (void)layoutSubviews;
- (float)preferredHeightForWidth:(float)width;

@end
