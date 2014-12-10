//
//  CSSyphonInjectCaptureViewController.m
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSSyphonInjectCaptureViewController.h"

@interface CSSyphonInjectCaptureViewController ()

@end

@implementation CSSyphonInjectCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)changeBuffer:(id)sender
{
    [self.captureObj changeBuffer];
}

- (IBAction)toggleFast:(id)sender
{
    [self.captureObj toggleFast];
}

- (IBAction)setDimensions:(id)sender
{
    [self.captureObj setBufferDimensions:self.x_offset y_offset:self.y_offset width:self.width height:self.height];
}


@end
