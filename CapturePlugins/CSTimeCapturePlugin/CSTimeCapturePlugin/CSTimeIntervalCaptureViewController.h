//
//  CSTimeIntervalCaptureViewController.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/12/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSTimeIntervalCapture.h"


@interface CSTimeIntervalCaptureViewController : NSViewController
@property (weak) CSTimeIntervalCapture *captureObj;
- (IBAction)reset:(id)sender;


@end
