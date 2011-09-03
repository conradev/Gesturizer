#import "GRWebSettingsController.h"
#import "GRRootListController.h"

@interface UIWebView (NoWarnings)
@property (nonatomic, readonly) UIScrollView *_scrollView;
@end

@implementation GRWebSettingsController

- (void)hideShadows {
	if ([_webView respondsToSelector:@selector(_scroller)]) {
		id scroller = [_webView _scroller];
		if ([scroller respondsToSelector:@selector(setShowBackgroundShadow:)])
			[scroller setShowBackgroundShadow:NO];
	}
	if ([_webView respondsToSelector:@selector(_scrollView)]) {
		UIScrollView *scrollView = [_webView _scrollView];
		if ([scrollView respondsToSelector:@selector(_setShowsBackgroundShadow:)])
			[scrollView _setShowsBackgroundShadow:NO];
	}
}

- (id)init {
	if ((self = [super init])) {
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		[_webView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
		[_webView setDelegate:self];
		_activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[_activityView startAnimating];
		_activityView.center = CGPointZero;
		[_activityView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
		[_webView addSubview:_activityView];
		[self hideShadows];
	}
	return self;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    NSString *urlString = [specifier propertyForKey:@"id"];
    if (urlString) {
        [self loadURL:[NSURL URLWithString:urlString]];
    }

    self.navigationItem.title = [specifier propertyForKey:@"label"];

	[super setSpecifier:specifier];
}

- (void)loadView {
	self.view = _webView;
}

- (void)dealloc {
	[_webView setDelegate:nil];
	[_webView stopLoading];
	[_webView release];
	[_activityView stopAnimating];
	[_activityView release];
	[super dealloc];
}

- (void)loadURL:(NSURL *)url {
	[self hideShadows];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setValue:[[UIDevice currentDevice] model] forHTTPHeaderField:@"X-Machine"];
	[_webView loadRequest:urlRequest];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	[self hideShadows];
	NSURL *url = [request URL];
	NSString *urlString = [url absoluteString];
	if ([urlString isEqualToString:@"about:Blank"])
		return YES;
	if ([urlString hasPrefix:@"http://kramerapps.com/cydia/gesturizer"])
		return YES;
    if ([urlString hasPrefix:@"mailto://"]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            [mailController setMailComposeDelegate:self];
            [mailController setToRecipients:[NSArray arrayWithObject:@"support@kramerapps.com"]];
            [mailController setSubject:@"Gesturizer Support"];

            NSString *error = nil;
            NSData *settingsData = [NSPropertyListSerialization dataFromPropertyList:[[GRRootListController sharedInstance] settingsDict] format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
            if (!error) {
                [mailController addAttachmentData:settingsData mimeType:@"application/x-plist" fileName:@"org.thebigboss.gesturizer.plist"];
            } else {
                [error release];
            }
            [self presentModalViewController:mailController animated:YES];
            [mailController release];

            return NO;
        }
    }

	[[UIApplication sharedApplication] openURL:url];
	return NO;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self hideShadows];
	[_activityView stopAnimating];
	[_activityView setHidden:YES];
}

@end
