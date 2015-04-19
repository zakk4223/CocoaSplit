//
//  CSElapsedTimeCaptureViewController.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSElapsedTimeCapture.h"
@interface CSElapsedTimeCaptureViewController : NSViewController
@property (weak) CSElapsedTimeCapture *captureObj;

- (IBAction)resetTime:(id)sender;

@end
