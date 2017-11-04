//
//  CSAdvancedAudioWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAdvancedAudioWindowController.h"
#import "CAMultiAudioEqualizer.h"

@interface CSAdvancedAudioWindowController ()

@end

@implementation CSAdvancedAudioWindowController



-(instancetype) init
{
    return [self initWithWindowNibName:@"CSAdvancedAudioWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)openEQWindow:(id)sender
{
    NSView *nodeView = [self.controller.multiAudioEngine.equalizer audioUnitNSView];
    if (nodeView)
    {
        self.eqWindow = [[NSWindow alloc] initWithContentRect:nodeView.frame styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        self.eqWindow.delegate = self;
        
        [self.eqWindow setReleasedWhenClosed:NO];
        
        [self.eqWindow center];
        
        [self.eqWindow setContentView:nodeView];
        [self.eqWindow makeKeyAndOrderFront:NSApp];
        
    }
    
}

-(void)windowWillClose:(NSNotification *)notification
{
    
    NSWindow *closingWindow = [notification object];
    if (closingWindow && self.eqWindow == closingWindow)
    {
        self.eqWindow = nil;
    }
}


@end
