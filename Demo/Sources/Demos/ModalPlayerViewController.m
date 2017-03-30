//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalPlayerViewController.h"

#import "UIWindow+LetterboxDemo.h"

#import <Masonry/Masonry.h>
#import <SRGAnalytics/SRGAnalytics.h>

static const UILayoutPriority LetterboxViewConstraintLessPriority = 850;
static const UILayoutPriority LetterboxViewConstraintMorePriority = 950;

@interface ModalPlayerViewController ()

@property (nonatomic) SRGMediaURN *URN;

@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained
@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *nowLabel;
@property (nonatomic, weak) IBOutlet UILabel *nextLabel;

// Switching to and from full-screen is made by adjusting the priority / constance of a constraint of the letterbox
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic, getter=isTransitioningToFullScreen) BOOL wantsFullScreen;

@property (nonatomic) NSMutableArray<SRGSegment *> *favoriteSegments;

@end

@implementation ModalPlayerViewController

#pragma mark Object lifecycle

- (instancetype)initWithURN:(SRGMediaURN *)URN
{
    SRGLetterboxService *service = [SRGLetterboxService sharedService];
    
    // If an equivalent view controller was dismissed for picture in picture of the same media, simply restore it
    if ([service.pictureInPictureDelegate isKindOfClass:[self class]] && [service.controller.URN isEqual:URN]) {
        return (ModalPlayerViewController *)service.pictureInPictureDelegate;
    }
    // Otherwise instantiate a fresh new one
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
        ModalPlayerViewController *viewController = [storyboard instantiateInitialViewController];
        viewController.favoriteSegments = @[].mutableCopy;
        viewController.URN = URN;
        return viewController;
    }
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    // Start with a hidden interface
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    // Always display the full-screen interface in landscape orientation
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    BOOL isLandscape = UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation) ? UIDeviceOrientationIsLandscape(deviceOrientation) : UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    [self.letterboxView setFullScreen:isLandscape animated:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(metadataDidChange:)
                                                 name:SRGLetterboxMetadataDidChangeNotification
                                               object:self.letterboxController];
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isMovingToParentViewController] || [self isBeingPresented]) {
        // Special case to test multi chapters and segments. Should be removed when an example is available in production
        if ([self.URN.uid containsString:@","]) {
            self.letterboxController.serviceURL = [NSURL URLWithString:@"https://play-mmf.herokuapp.com"];
        }
        else {
            self.letterboxController.serviceURL = nil;
        }
        
        [self.letterboxController playURN:self.URN];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self isMovingFromParentViewController] || [self isBeingDismissed]) {
        if (! self.letterboxController.pictureInPictureActive) {
            [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
        }
    }
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        BOOL isLandscape = (size.width > size.height);
        [self.letterboxView setFullScreen:isLandscape animated:NO];
    } completion:nil];
}

#pragma mark Data

- (void)reloadData
{
    [self reloadDataOverriddenWithMedia:nil];
}

- (void)reloadDataOverriddenWithMedia:(SRGMedia *)media
{
    if (! media) {
        if (self.URN.mediaType == SRGMediaTypeVideo && self.letterboxController.fullLengthMedia) {
            media = self.letterboxController.fullLengthMedia;
        }
        else {
            media = self.letterboxController.media;
        }
    }
    
    self.titleLabel.text = media.title;
    
    SRGChannel *channel = self.letterboxController.channel;
    self.nowLabel.text = channel.currentProgram.title ? [NSString stringWithFormat:@"Now: %@", channel.currentProgram.title] : nil;
    self.nextLabel.text = channel.nextProgram.title ? [NSString stringWithFormat:@"Next: %@", channel.nextProgram.title] : nil;
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topPresentedViewController = [UIApplication sharedApplication].keyWindow.topPresentedViewController;
    return topPresentedViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topPresentedViewController = [UIApplication sharedApplication].keyWindow.topPresentedViewController;
    [topPresentedViewController presentViewController:self animated:YES completion:^{
        completionHandler(YES);
    }];
}

- (void)letterboxDidStartPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_start"];
}

- (void)letterboxDidEndPictureInPicture
{
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"pip_end"];
}

- (void)letterboxDidStopPlaybackFromPictureInPicture
{
    [[SRGLetterboxService sharedService] disableForController:self.letterboxController];
}

#pragma mark SRGLetterboxViewDelegate protocol

- (void)letterboxViewWillAnimateUserInterface:(SRGLetterboxView *)letterboxView
{
    [self.view layoutIfNeeded];
    [letterboxView animateAlongsideUserInterfaceWithAnimations:^(BOOL hidden, CGFloat heightOffset) {
        self.letterboxAspectRatioConstraint.constant = heightOffset;
        self.closeButton.alpha = (hidden && ! self.letterboxController.error && self.URN) ? 0.f : 1.f;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didScrollWithSegment:(SRGSegment *)segment interactive:(BOOL)interactive
{
    if (interactive) {
        SRGMedia *media = segment ? [self.letterboxController.mediaComposition mediaForSegment:segment] : nil;
        [self reloadDataOverriddenWithMedia:media];
    }
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    void (^animations)(void) = ^{
        if (fullScreen) {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintMorePriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintLessPriority;
        }
        else {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLessPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintMorePriority;
        }
    };
    
    self.wantsFullScreen = fullScreen;
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        } completion:completionHandler];
    }
    else {
        animations();
        completionHandler(YES);
    }
}

- (BOOL)letterboxViewShouldDisplayFullScreenToggleButton:(SRGLetterboxView *)letterboxView
{
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

- (BOOL)letterboxView:(SRGLetterboxView *)letterboxView shouldFavoriteSegment:(SRGSegment *)segment
{
    return [self.favoriteSegments containsObject:segment];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didLongPressWithSegment:(SRGSegment *)segment
{
    if ([self.favoriteSegments containsObject:segment]) {
        [self.favoriteSegments removeObject:segment];
    }
    else {
        [self.favoriteSegments addObject:segment];
    }
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)hideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:YES];
}

- (IBAction)showControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:YES];
}

- (IBAction)forceHideControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:YES animated:YES togglable:NO];
}

- (IBAction)forceShowControls:(id)sender
{
    [self.letterboxView setUserInterfaceHidden:NO animated:YES togglable:NO];
}

- (IBAction)fullScreen:(id)sender
{
    [self.letterboxView setFullScreen:YES animated:YES];
}

- (IBAction)toggleAlwaysHideTimeline:(UISwitch *)sender
{
    [self.letterboxView setTimelineAlwaysHidden:sender.on animated:YES];
}

#pragma mark Notifications

- (void)metadataDidChange:(NSNotification *)notification
{
    [self reloadDataOverriddenWithMedia:self.letterboxController.segmentMedia];
}

@end
