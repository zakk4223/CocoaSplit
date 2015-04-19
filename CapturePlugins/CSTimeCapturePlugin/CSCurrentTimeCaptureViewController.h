//
//  CSCurrentTimeCaptureViewController.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CSCurrentTimeCapture.h"

@interface CSCurrentTimeCaptureViewController : NSViewController

@property (strong) NSArray *styleSortDescriptors;
@property (weak) CSCurrentTimeCapture *captureObj;

@end
