//
//  CSFFMpegCaptureViewController.m
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/14/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFFMpegCaptureViewController.h"

@interface CSFFMpegCaptureViewController ()

@end

@implementation CSFFMpegCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


- (IBAction)chooseFile:(id)sender
{
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = YES;
    panel.allowsMultipleSelection = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.captureObj.inputPath = panel.URL.path;
        }
        
    }];
    
}

- (IBAction)nextAction:(id)sender
{
    [self.captureObj.player next];
}

- (IBAction)sliderValueChanged:(id)sender
{
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    BOOL startingDrag = event.type == NSLeftMouseDown;
    BOOL endingDrag = event.type == NSLeftMouseUp;
    BOOL dragging = event.type == NSLeftMouseDragged;
    
    
    if (startingDrag) {
        self.captureObj.player.muted = YES;
        self.captureObj.player.seeking = YES;
    }
    
    
    if (endingDrag) {
        self.captureObj.player.muted = NO;
        self.captureObj.player.seeking = NO;
        self.captureObj.player.audio_needs_restart = YES;
    }
}
    

@end
