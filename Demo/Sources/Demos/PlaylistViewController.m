//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlaylistViewController.h"

#import "Playlist.h"
#import "SettingsViewController.h"
#import "UIWindow+LetterboxDemo.h"

#import <libextobjc/libextobjc.h>

@interface PlaylistViewController ()

@property (nonatomic) Playlist *playlist;

@property (nonatomic, weak) IBOutlet SRGLetterboxView *letterboxView;
@property (nonatomic) IBOutlet SRGLetterboxController *letterboxController;     // top-level object, retained

@property (nonatomic, weak) IBOutlet UIButton *previousButton;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;

@property (nonatomic, weak) IBOutlet UILabel *continuousPlaybackLabel;

@property (nonatomic, weak) IBOutlet UIView *settingsView;

// Switching to and from full-screen is made by adjusting the priority / constance of a constraint of the letterbox
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *letterboxAspectRatioConstraint;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *letterboxMarginConstraints;

@end

@implementation PlaylistViewController

#pragma mark Object lifecycle

- (instancetype)initWithMedias:(NSArray<SRGMedia *> *)medias
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];
    PlaylistViewController *viewController = [storyboard instantiateInitialViewController];

    Playlist *playlist = [[Playlist alloc] initWithMedias:medias];
    playlist.continuousPlaybackTransitionDuration = 10.;
    viewController.playlist = playlist;

    viewController.letterboxController.serviceURL = ApplicationSettingServiceURL();
    viewController.letterboxController.updateInterval = ApplicationSettingUpdateInterval();
    viewController.letterboxController.globalHeaders = ApplicationSettingGlobalHeaders();
    
    return viewController;
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
    
    self.letterboxController.playlistDataSource = self.playlist;
    
    self.letterboxView.controller = self.letterboxController;
    [self.letterboxView setUserInterfaceHidden:YES animated:NO togglable:YES];
    
    [[SRGLetterboxService sharedService] enableWithController:self.letterboxController pictureInPictureDelegate:self];
    
    [self updatePlaylistButtons];
    @weakify(self)
    [self.letterboxController addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1., NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self)
        [self updatePlaylistButtons];
    }];
    
    self.continuousPlaybackLabel.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackDidContinueAutomatically:)
                                                 name:SRGLetterboxPlaybackDidContinueAutomaticallyNotification
                                               object:self.letterboxController];
    
    SRGMedia *firstMedia = self.playlist.medias.firstObject;
    if (firstMedia) {
        [self.letterboxController playMedia:firstMedia withChaptersOnly:NO];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark UI

- (void)updatePlaylistButtons
{
    self.previousButton.hidden = (! self.letterboxController.previousMedia);
    self.nextButton.hidden = (! self.letterboxController.nextMedia);
}

- (void)updateContinuousPlaybackLabelWithText:(NSString *)text
{
    self.continuousPlaybackLabel.alpha = 1.f;
    self.continuousPlaybackLabel.text = text;
    [UIView animateWithDuration:3 delay:0. options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.continuousPlaybackLabel.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.continuousPlaybackLabel.text = nil;
    }];
}

#pragma mark SRGLetterboxPictureInPictureDelegate protocol

- (BOOL)letterboxDismissUserInterfaceForPictureInPicture
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

- (BOOL)letterboxShouldRestoreUserInterfaceForPictureInPicture
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    return topViewController != self;
}

- (void)letterboxRestoreUserInterfaceForPictureInPictureWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.topViewController;
    [topViewController presentViewController:self animated:YES completion:^{
        completionHandler(YES);
    }];
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
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView toggleFullScreen:(BOOL)fullScreen animated:(BOOL)animated withCompletionHandler:(nonnull void (^)(BOOL))completionHandler
{
    static const UILayoutPriority LetterboxViewConstraintLowerPriority = 850;
    static const UILayoutPriority LetterboxViewConstraintGreaterPriority = 950;
    
    void (^animations)(void) = ^{
        if (fullScreen) {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintGreaterPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintLowerPriority;
            self.settingsView.alpha = 0.f;
        }
        else {
            self.letterboxBottomConstraint.priority = LetterboxViewConstraintLowerPriority;
            self.letterboxAspectRatioConstraint.priority = LetterboxViewConstraintGreaterPriority;
            self.settingsView.alpha = 1.f;
        }
    };
    
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

- (void)letterboxView:(SRGLetterboxView *)letterboxView didEngageInContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self updateContinuousPlaybackLabelWithText:[NSString stringWithFormat:@"Suggested media '%@' actively played by the user.", upcomingMedia.title]];
}

- (void)letterboxView:(SRGLetterboxView *)letterboxView didCancelContinuousPlaybackWithUpcomingMedia:(SRGMedia *)upcomingMedia
{
    [self updateContinuousPlaybackLabelWithText:[NSString stringWithFormat:@"Continuous playback canceled for media '%@'.", upcomingMedia.title]];
}

#pragma mark Notifications

- (void)playbackDidContinueAutomatically:(NSNotification *)notification
{
    SRGMedia *media = notification.userInfo[SRGLetterboxMediaKey];
    [self updateContinuousPlaybackLabelWithText:[NSString stringWithFormat:@"Autoplay with media '%@'.", media.title]];
}

#pragma mark Actions

- (IBAction)playPreviousMedia:(id)sender
{
    [self.letterboxController playPreviousMedia];
    [self updatePlaylistButtons];
}

- (IBAction)playNextMedia:(id)sender
{
    [self.letterboxController playNextMedia];
    [self updatePlaylistButtons];
}

- (IBAction)toggleView:(id)sender
{
    if (self.letterboxView.controller) {
        self.letterboxView.controller = nil;
    }
    else {
        self.letterboxView.controller = self.letterboxController;
    }
}

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeMargins:(UISlider *)slider
{
    [self.letterboxMarginConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        constraint.constant = slider.maximumValue - slider.value;
    }];
}

@end