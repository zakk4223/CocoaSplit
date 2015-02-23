//
//  AVFCaptureViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AVFCapture.h"


@interface AVFCaptureViewController : NSViewController
@property (weak) AVFCapture *captureObj;
@property (strong) NSDictionary *renderStyleMap;
@property (strong) NSArray *styleSortDescriptors;

@end
