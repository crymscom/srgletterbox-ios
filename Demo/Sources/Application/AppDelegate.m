//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <HockeySDK/HockeySDK.h>

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
#ifndef DEBUG
    
#ifdef NIGHTLY
    NSString *hockeyIdentifier = @"";
#else
    NSString *hockeyIdentifier = @"13cd3fae0acd46138c2e2bbf20d016c2";
#endif
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:hockeyIdentifier];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif
    
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierRTS
                                                     comScoreVirtualSite:@"app-test-v"
                                                     netMetrixIdentifier:@"test"];
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:demosViewController];

    return YES;
}

@end
