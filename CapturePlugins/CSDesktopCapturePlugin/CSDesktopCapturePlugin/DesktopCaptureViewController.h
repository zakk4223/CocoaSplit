//
//  DesktopCaptureViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DesktopCapture.h"

@interface DesktopCaptureViewController : NSViewController
@property (weak) DesktopCapture *captureObj;
@property (weak) IBOutlet NSWindow *cropSelectionWindow;
@property (strong) NSDictionary *renderStyleMap;
@property (strong) NSArray *styleSortDescriptors;
- (IBAction)closeOverlayView:(id)sender;
-(IBAction)resetCroppedArea:(id)sender;

@end
