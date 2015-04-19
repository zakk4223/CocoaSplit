//
//  FileTextCaptureViewController.h
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileTextCapture.h"

@interface FileTextCaptureViewController : NSViewController

@property (weak) FileTextCapture *captureObj;

- (IBAction)chooseFile:(id)sender;

@end
