//
//  CSDeckLinkCaptureViewController.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSDeckLinkCaptureViewController.h"

@interface CSDeckLinkCaptureViewController ()

@end

@implementation CSDeckLinkCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.renderStyleMap = @{@"On Frame Arrival": @(kCSRenderFrameArrived),
                                @"On Internal Frame Tick": @(kCSRenderOnFrameTick),
                                @"Asynchronous": @(kCSRenderAsync)
                                };
        
        self.styleSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];
        
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
