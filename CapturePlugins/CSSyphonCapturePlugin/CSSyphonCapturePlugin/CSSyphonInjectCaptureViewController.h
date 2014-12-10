//
//  CSSyphonInjectCaptureViewController.h
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSyphonInjectCapture.h"


@interface CSSyphonInjectCaptureViewController : NSViewController


@property (weak) CSSyphonInjectCapture *captureObj;
@property (assign) int x_offset;
@property (assign) int y_offset;
@property (assign) int width;
@property (assign) int height;


- (IBAction)changeBuffer:(id)sender;
- (IBAction)toggleFast:(id)sender;
- (IBAction)setDimensions:(id)sender;

@end
