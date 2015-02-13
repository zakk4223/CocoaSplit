//
//  CSCurrentTimeCaptureViewController.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCurrentTimeCaptureViewController.h"

@interface CSCurrentTimeCaptureViewController ()

@end

@implementation CSCurrentTimeCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.styleSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];
    
    // Do view setup here.
}

@end
