#import <Preferences/Preferences.h>
#import <MessageUI/MessageUI.h>

@interface GRWebSettingsController : PSViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate> {
@private
	UIActivityIndicatorView *_activityView;
	UIWebView *_webView;
}

- (void)loadURL:(NSURL *)url;

@end
