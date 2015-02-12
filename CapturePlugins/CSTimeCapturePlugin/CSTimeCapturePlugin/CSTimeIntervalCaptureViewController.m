//
//  CSTimeIntervalCaptureViewController.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/12/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeIntervalCaptureViewController.h"
#import "CSTimeIntervalCapture.h"


@interface CSTimeIntervalCaptureViewController ()

@end

@implementation CSTimeIntervalCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)reset:(id)sender
{
    [(CSTimeIntervalCapture *)self.captureObj reset];
}
@end
