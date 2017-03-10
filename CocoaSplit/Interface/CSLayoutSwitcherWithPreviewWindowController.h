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


@interface CSLayoutSwitcherWithPreviewWindowController : NSWindowController
@property (strong) NSArray *layouts;
@property (weak) IBOutlet NSView *gridView;

-(void)layoutClicked:(SourceLayout *)layout withEvent:(NSEvent *)event;
@property (weak) IBOutlet NSView *transitionView;

@end
