//
//  CmdLineDelegate.m
//  CocoaSplit
//
//  Created by Zakk on 4/8/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "CmdLineDelegate.h"

@implementation CmdLineDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    NSUserDefaults *cmdargs = [NSUserDefaults standardUserDefaults];
    BOOL loadSavedSettings = YES;
    
    loadSavedSettings = [cmdargs boolForKey:@"loadSettings"];
    
    if ([cmdargs objectForKey:@"loadSettings"])
    {
        loadSavedSettings = [cmdargs boolForKey:@"loadSettings"];
    }

    if (loadSavedSettings == YES)
    {
        [self.captureController loadSettings];
    }
    
    
    [self.captureController loadCmdlineSettings:cmdargs];
    [[NSProcessInfo processInfo] disableSuddenTermination];

    
    [self.captureController startStream];
    
    
    
}


-(NSApplicationTerminateReply) applicationShouldTerminate: (NSNotification *)notification
{
    
    NSLog(@"STOPPING STREAM!");
    
    [self.captureController stopStream];
    
    return NSTerminateNow;
    
    
    
}


@end
