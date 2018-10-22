//
//  CSLayoutSwitcherWithPreviewWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 3/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "CSPreviewGLLayer.h"
#import "CSLayoutSwitcherViewController.h"
#import "SourceLayout.h"


@class PreviewView;

@interface CSLayoutSwitcherWithPreviewWindowController : NSWindowController
{

    CSLayoutSwitcherViewController *_layoutViewController;
    
}
@property (strong) NSArray *layouts;

@property (strong) IBOutlet NSLayoutConstraint *liveConstraint;
@property (weak) LayoutRenderer *previewRenderer;
@property (weak) LayoutRenderer *liveRenderer;
@property (weak) IBOutlet CSLayoutSwitcherView *previewView;
@property (weak) IBOutlet CSLayoutSwitcherView *liveView;

@property (weak) IBOutlet NSView *gridView;

@property (weak) IBOutlet NSView *transitionView;

@end
