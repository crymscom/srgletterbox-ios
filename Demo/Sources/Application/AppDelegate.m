//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AppDelegate.h"

#import "DemosViewController.h"

#import <SRGAnalytics/SRGAnalytics.h>
#import <HockeySDK/HockeySDK.h>
#import <TCCore/TCCore.h>

@implementation AppDelegate

#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"0344df58d3074e11947c2a6d93d5a76a"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif
    
    [TCDebug setDebugLevel:TCLogLevel_Verbose];
    [TCDebug setNotificationLog:YES];
    
    [[SRGAnalyticsTracker sharedTracker] startWithBusinessUnitIdentifier:SRGAnalyticsBusinessUnitIdentifierTEST
                                                       accountIdentifier:3601
                                                     containerIdentifier:2
                                                     netMetrixIdentifier:@"test"];
    
    DemosViewController *demosViewController = [[DemosViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:demosViewController];

    return YES;
}

@end
