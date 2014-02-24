//
//  AppDelegate.m
//  FlappyFelipe
//
//  Created by Main Account on 2/13/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
