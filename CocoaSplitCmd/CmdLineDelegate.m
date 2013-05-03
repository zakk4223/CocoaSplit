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
    [self.captureController loadSettings];
    [self.captureController loadCmdlineSettings];
    
    
    [self.captureController startStream];
    
    // Insert code here to initialize your application
    
    
}


-(void) applicationWillTerminate: (NSNotification *)notification
{
    
    
    
}


@end
