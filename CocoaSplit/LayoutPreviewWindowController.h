//
//  LayoutPreviewWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 9/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CaptureController.h"
#import "PreviewView.h"


@interface LayoutPreviewWindowController : NSWindowController


@property (weak) IBOutlet PreviewView *openGLView;
@property (weak) CaptureController *captureController;
@property (strong) NSMutableArray *sourceLayouts;
@property (strong) NSString *selectedLayoutName;

-(void)goLive;
-(void)saveLayout;


@end
