//
//  CSAnimationWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 8/7/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreviewView;


@interface CSAnimationWindowController : NSWindowController <NSTableViewDelegate>
{
    NSPopover *_animatepopOver;
    
}
@property (strong) PreviewView *activePreviewView;
@property (strong) PreviewView *livePreviewView;
@property (assign) bool stagingHidden;


- (IBAction)openAnimatePopover:(NSButton *)sender;

@end
