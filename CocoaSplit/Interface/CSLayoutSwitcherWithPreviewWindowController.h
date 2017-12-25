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


@interface CSLayoutSwitcherWithPreviewWindowController : NSWindowController
{

    CSLayoutSwitcherViewController *_layoutViewController;
    
}
@property (strong) NSArray *layouts;
@property (weak) IBOutlet NSView *gridView;

@property (weak) IBOutlet NSView *transitionView;

@end
