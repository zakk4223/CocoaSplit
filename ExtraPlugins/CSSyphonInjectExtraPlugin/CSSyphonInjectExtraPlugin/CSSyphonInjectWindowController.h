//
//  CSSyphonInjectWindowController.h
//  CSSyphonInjectExtraPlugin
//
//  Created by Zakk on 10/1/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@class CSSyphonInject;

@interface CSSyphonInjectWindowController : NSWindowController

@property (weak) CSSyphonInject *injector;

@property (weak) IBOutlet NSArrayController *applicationArrayController;
- (IBAction)injectProcesses:(id)sender;

@end
