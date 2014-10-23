//
//  CreateLayoutViewController.h
//  CocoaSplit
//
//  Created by Zakk on 9/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"
#import "CaptureController.h"

@interface CreateLayoutViewController : NSViewController <NSPopoverDelegate>

@property (weak) CaptureController *controller;
@property (weak) NSPopover *popover;

@property (strong) SourceLayout *sourceLayout;

- (IBAction)createButtonClicked:(id)sender;

@end
