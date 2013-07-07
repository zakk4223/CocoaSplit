//
//  main.m
//  CocoaSplitCmd
//
//  Created by Zakk on 4/6/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureController.h"
#import "CmdLineDelegate.h"



int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        NSLog(@"Hello, World!");
        
        
        
        CaptureController *cmdController = [[CaptureController alloc] init];
        /*
        [cmdController loadSettings];
        
        if ([cmdController startStream] == YES)
        {
            NSLog(@"START STREAM");
        } else {
            NSLog(@"COULDN'T START STREAM :(");
        }
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
        */
        
        
        
        CmdLineDelegate *delegate = [[CmdLineDelegate alloc] init];

NSApplication *app = [NSApplication sharedApplication];

[app setDelegate:delegate];
delegate.captureController = cmdController;

[NSApp run];



        
        
    }
    return 0;
}

