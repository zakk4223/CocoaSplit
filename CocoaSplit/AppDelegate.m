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
    
    
    [_window setReleasedWhenClosed:NO];
    
    
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarSmartFolder.icns"];
    
    NSImage *useimg = [[NSImage alloc] initWithSize:NSMakeSize(64,64)];
    [useimg addRepresentation:img.representations[0]];
    
    NSImage *altImg = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarMoviesFolder.icns"];
    
    self.layoutSequenceButton.image = useimg;
    self.layoutSequenceButton.alternateImage = altImg;

    [[NSBundle mainBundle] loadNibNamed:@"LogWindow" owner:self.captureController topLevelObjects:nil];
    
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.captureController setupLogging];
    });*/

    //Force loading of python stuff now
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [CaptureController sharedAnimationObj];
    });
    
    
    
    [self.captureController loadSettings];
    //self.captureController.audioConstraint.constant = 0;

    
    // Insert code here to initialize your application
    
    
}


-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (self.captureController)
    {
        return [self.captureController applicationShouldTerminate:sender];
    }
    
    return NSTerminateNow;
}


-(void) applicationWillTerminate: (NSNotification *)notification
{
    
    
    [self.captureController saveSettings];
    
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [_window setIsVisible:YES];
    return YES;
}



@end
