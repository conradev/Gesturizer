#import "GRGestureRecordingViewController.h"

@implementation GRGestureRecordingViewController

@synthesize delegate=_delegate;

- (id)initWithDelegate:(id<GRGestureRecordingDelegate>)someDelegate {
    if ((self = [self init])) {
        self.delegate = someDelegate;
    }
    return self;
}

- (void)dealloc {
    [recordingView release];
    self.delegate = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [super viewWillDisappear:animated];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    recordingView = [[GRGestureRecordingView alloc] initWithFrame:self.view.frame];
    recordingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    recordingView.delegate = self.delegate;
    [self.view addSubview:recordingView];
}

@end
