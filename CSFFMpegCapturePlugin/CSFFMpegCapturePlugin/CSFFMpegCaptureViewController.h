//
//  CSFFMpegCaptureViewController.h
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/14/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSFFMpegCapture.h"

@interface CSFFMpegCaptureViewController : NSViewController

@property (weak) CSFFMpegCapture *captureObj;

- (IBAction)chooseFile:(id)sender;
- (IBAction)nextAction:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;

@end
