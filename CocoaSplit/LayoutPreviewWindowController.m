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

@synthesize selectedLayoutName = _selectedLayoutName;

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


-(void)showWindow:(id)sender
{
    if (self.openGLView)
    {
        [self.openGLView restartDisplayLink];
    }
    [super showWindow:sender];
}


-(void)windowWillClose:(NSNotification *)notification
{
    [self.openGLView stopDisplayLink];

    [self.openGLView.sourceLayout.sourceList removeAllObjects];
    
    
}

-(NSString *)selectedLayoutName
{
    return _selectedLayoutName;
}

-(void) setSelectedLayoutName:(NSString *)selectedLayoutName
{
    _selectedLayoutName = selectedLayoutName;
    SourceLayout *useLayout = [self.captureController getLayoutForName:selectedLayoutName];
    SourceLayout *newLayout = [useLayout copy];
    [newLayout restoreSourceList];
    self.openGLView.sourceLayout =  newLayout;
}

-(void) saveLayout
{
    
    SourceLayout *realLayout = [self.captureController getLayoutForName:self.openGLView.sourceLayout.name];

    if (self.openGLView.sourceLayout && realLayout)
    {
        [self.openGLView.sourceLayout saveSourceList];
        realLayout.savedSourceListData = self.openGLView.sourceLayout.savedSourceListData;
    }
}


-(void) goLive
{
    
    SourceLayout *realLayout = [self.captureController getLayoutForName:self.openGLView.sourceLayout.name];
    
    if (self.openGLView.sourceLayout && realLayout)
    {
        [self.openGLView.sourceLayout saveSourceList];
        realLayout.savedSourceListData = self.openGLView.sourceLayout.savedSourceListData;
        [realLayout restoreSourceList];
    }
}

@end
