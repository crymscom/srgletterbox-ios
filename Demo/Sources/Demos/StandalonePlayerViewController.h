//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <SRGLetterbox/SRGLetterbox.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StandalonePlayerViewController : UIViewController <SRGLetterboxPictureInPictureDelegate, SRGLetterboxViewDelegate>

- (instancetype)initWithURN:(nullable NSString *)URN;

@end

@interface StandalonePlayerViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
