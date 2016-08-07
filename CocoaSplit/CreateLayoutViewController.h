//
//  CreateLayoutViewController.h
//  CocoaSplit
//
//  Created by Zakk on 9/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"



@interface CreateLayoutViewController : NSViewController <NSPopoverDelegate>

@property (weak) NSPopover *popover;

@property (strong) SourceLayout *sourceLayout;
@property (assign) bool createDialog;


@property (assign) int canvas_width;
@property (assign) int canvas_height;

- (IBAction)createButtonClicked:(id)sender;
-(instancetype) initForBuiltin;


@end
