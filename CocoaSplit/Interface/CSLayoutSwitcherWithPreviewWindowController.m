//
//  CSLayoutSwitcherWithPreviewWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 3/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSwitcherWithPreviewWindowController.h"
#import "CaptureController.h"
#import "AppDelegate.h"
#import "CSLayoutSwitcherView.h"

@interface CSLayoutSwitcherWithPreviewWindowController ()

@end

@implementation CSLayoutSwitcherWithPreviewWindowController


-(instancetype) init
{
    
    
    return [self initWithWindowNibName:@"CSLayoutSwitcherWithPreviewWindowController"];
    
}




-(void)windowWillEnterFullScreen:(NSNotification *)notification
{
    [self.transitionView setHidden:YES];
}

-(void)windowWillExitFullScreen:(NSNotification *)notification
{
    [self.transitionView setHidden:NO];
}



-(NSArray *)layouts
{
    if (_layoutViewController)
    {
        return _layoutViewController.layouts;
    }
    
    return nil;
}


-(void)setLayouts:(NSArray *)layouts
{
    
    if (!_layoutViewController)
    {
        _layoutViewController = [[CSLayoutSwitcherViewController alloc] init];
        _layoutViewController.view = self.gridView;
    }
    
    _layoutViewController.layouts = layouts;
}

-(void)windowWillClose:(NSNotification *)notification
{
    _layoutViewController = nil;
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
