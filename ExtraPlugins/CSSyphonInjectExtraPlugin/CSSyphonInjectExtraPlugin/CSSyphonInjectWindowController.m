//
//  CSSyphonInjectWindowController.m
//  CSSyphonInjectExtraPlugin
//
//  Created by Zakk on 10/1/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSSyphonInjectWindowController.h"
#import "CSSyphonInject.h"


@interface CSSyphonInjectWindowController ()

@end

@implementation CSSyphonInjectWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)injectProcesses:(id)sender
{
    for (NSRunningApplication *toInject in self.applicationArrayController.selectedObjects)
    {
        [self.injector doInject:toInject];
    }
}


@end
