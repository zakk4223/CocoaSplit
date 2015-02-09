//
//  CSElapsedTimeCaptureViewController.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSElapsedTimeCaptureViewController.h"
#import "CSElapsedTimeCapture.h"

@interface CSElapsedTimeCaptureViewController ()

@end

@implementation CSElapsedTimeCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)resetTime:(id)sender
{
    ((CSElapsedTimeCapture *)self.captureObj).startDate = [NSDate date];
}


@end
