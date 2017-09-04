//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAccessibilityView.h"

#import "NSBundle+SRGLetterbox.h"

@implementation SRGAccessibilityView

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return (self.letterboxView.controller.media.mediaType == SRGMediaTypeAudio) ? SRGLetterboxAccessibilityLocalizedString(@"Audio", @"The main area on the letterbox view, where the audio or its thumbnail is displayed") : SRGLetterboxAccessibilityLocalizedString(@"Video", @"The main area on the letterbox view, where the video or its thumbnail is displayed");
}

- (NSString *)accessibilityHint
{
    SRGLetterboxController *controller = self.letterboxView.controller;
    if (! controller.error && SRGDataProviderAvailabilityForMediaMetadata(controller.media) == SRGMediaAvailabilityAvailable) {
        return self.letterboxView.userInterfaceTogglable ? SRGLetterboxAccessibilityLocalizedString(@"Double tap to display or hide player controls.", @"Hint for the letterbox view") : nil;
    }
    else {
        return nil;
    }
}

@end
