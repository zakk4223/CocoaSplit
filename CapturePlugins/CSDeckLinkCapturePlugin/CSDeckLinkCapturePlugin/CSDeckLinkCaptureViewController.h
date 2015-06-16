//
//  CSDeckLinkCaptureViewController.h
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSDeckLinkCapture.h"

@interface CSDeckLinkCaptureViewController : NSViewController

@property (weak) CSDeckLinkCapture *captureObj;
@property (strong) NSDictionary *renderStyleMap;
@property (strong) NSArray *styleSortDescriptors;

@end
