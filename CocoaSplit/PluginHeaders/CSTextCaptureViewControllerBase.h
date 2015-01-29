//
//  CSTextCaptureViewControllerBase.h
//  CocoaSplit
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSTextCaptureBase.h"


@interface CSTextCaptureViewControllerBase : NSViewController
@property (weak) CSTextCaptureBase *captureObj;
- (IBAction)openFontPanel:(id)sender;

@end
