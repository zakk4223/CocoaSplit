//
//  AppDelegate.m
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.captureController loadSettings];
    
    // Insert code here to initialize your application
    
    
}


-(void) applicationWillTerminate: (NSNotification *)notification
{
    
    
    [self.captureController saveSettings];
    
}


@end
