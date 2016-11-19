//
//  CSStreamOutputWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 8/7/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class CaptureController;

@interface CSStreamOutputWindowController : NSWindowController


@property (weak) CaptureController *controller;

@property (weak) IBOutlet NSTableView *outputTableView;
@property (strong) NSIndexSet *selectedCaptureDestinations;


- (IBAction)outputEditClicked:(id)sender;
- (IBAction)outputSegmentedAction:(NSButton *)sender;


@end
