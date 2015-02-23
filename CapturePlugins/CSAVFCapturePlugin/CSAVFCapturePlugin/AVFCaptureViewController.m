//
//  AVFCaptureViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "AVFCaptureViewController.h"

@interface AVFCaptureViewController ()

@end

@implementation AVFCaptureViewController

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

@end
