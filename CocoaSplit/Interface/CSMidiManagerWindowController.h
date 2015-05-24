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
@property (weak) NSArray *responderList;
@property (strong) NSMutableArray *commandIdentfiers;




- (IBAction)learnPushed:(id)sender;
@end
