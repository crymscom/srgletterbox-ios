//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LetterboxBaseTestCase.h"

#import <SRGLetterbox/SRGLetterbox.h>

@interface PlaybackSettingsTestCase : LetterboxBaseTestCase

@end

@implementation PlaybackSettingsTestCase

#pragma mark Tests

- (void)testDefaultSettings
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    XCTAssertEqual(settings.streamType, SRGStreamTypeNone);
    XCTAssertEqual(settings.quality, SRGQualityNone);
    XCTAssertFalse(settings.standalone);
    XCTAssertEqual(settings.startBitRate, SRGDefaultStartBitRate);
}

- (void)testCustomSettings
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.standalone = YES;
    settings.startBitRate = 1200;
    
    XCTAssertEqual(settings.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settings.quality, SRGQualityHD);
    XCTAssertTrue(settings.standalone);
    XCTAssertEqual(settings.startBitRate, 1200);
}

- (void)testCopy
{
    SRGLetterboxPlaybackSettings *settings = [[SRGLetterboxPlaybackSettings alloc] init];
    settings.streamType = SRGStreamTypeDVR;
    settings.quality = SRGQualityHD;
    settings.standalone = YES;
    settings.startBitRate = 1200;
    
    // Make a copy
    SRGLetterboxPlaybackSettings *settingsCopy = [settings copy];
    
    // Modify the original
    settings.streamType = SRGStreamTypeNone;
    settings.quality = SRGQualityNone;
    settings.standalone = NO;
    settings.startBitRate = SRGDefaultStartBitRate;
    
    // Check that the copy is identical to the original
    XCTAssertEqual(settingsCopy.streamType, SRGStreamTypeDVR);
    XCTAssertEqual(settingsCopy.quality, SRGQualityHD);
    XCTAssertTrue(settingsCopy.standalone);
    XCTAssertEqual(settingsCopy.startBitRate, 1200);
}

@end
