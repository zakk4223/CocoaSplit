//
//  DesktopCaptureViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DesktopCapture.h"
#import "CSOverlayWindow.h"
@interface DesktopCaptureViewController : NSViewController
@property (weak) DesktopCapture *captureObj;
@property (weak) IBOutlet CSOverlayWindow *cropSelectionWindow;
@property (strong) NSDictionary *renderStyleMap;
@property (strong) NSArray *styleSortDescriptors;
- (IBAction)closeOverlayView:(id)sender;
-(IBAction)resetCroppedArea:(id)sender;

@end
