//
//  CSMidiManagerWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 5/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MIKMIDI.h"


@class CaptureController;


@interface CSMidiManagerWindowController : NSWindowController


@property (weak) CaptureController *captureController;
@property (strong) NSArray *responderList;
@property (strong) NSMutableArray *commandIdentfiers;
@property (strong) NSWindow *modalWindow;




- (IBAction)learnPushed:(id)sender;
-(IBAction)clearPushed:(id)sender;


-(void)learnedDone;

@end
