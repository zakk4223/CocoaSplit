//
//  CSLayoutCaptureViewController.h
//  CSLayoutCapturePlugin
//
//  Created by Zakk on 10/15/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutCapture.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSLayoutCaptureViewController : NSViewController
@property (weak) CSLayoutCapture *captureObj;

@end

NS_ASSUME_NONNULL_END
