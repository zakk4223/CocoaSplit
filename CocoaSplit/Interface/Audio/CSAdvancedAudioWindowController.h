//
//  CSAdvancedAudioWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CaptureController.h"
@interface CSAdvancedAudioWindowController : NSWindowController


@property (weak) CaptureController *controller;
@property (strong) NSWindow *eqWindow;

- (IBAction)openEQWindow:(id)sender;


@end
