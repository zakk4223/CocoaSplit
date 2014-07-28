//
//  InputPopupControllerViewController.h
//  CocoaSplit
//
//  Created by Zakk on 7/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InputPopupControllerViewController : NSViewController <NSPopoverDelegate, NSWindowDelegate>
@property (strong) IBOutlet NSObjectController *InputController;
@property (strong) NSWindow *popoverWindow;
@property (strong) NSPopover *myPopover;

@end
