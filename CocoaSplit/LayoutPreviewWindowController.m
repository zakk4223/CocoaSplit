//
//  LayoutPreviewWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 9/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "LayoutPreviewWindowController.h"
#import "SourceLayout.h"

@interface LayoutPreviewWindowController ()

@end

@implementation LayoutPreviewWindowController

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


-(void)windowWillClose:(NSNotification *)notification
{
    [self.openGLView.sourceLayout.sourceList removeAllObjects];
    
}
@end
