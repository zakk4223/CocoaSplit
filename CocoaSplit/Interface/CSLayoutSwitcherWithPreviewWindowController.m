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
#import "PreviewView.h"

@interface CSLayoutSwitcherWithPreviewWindowController ()

@end

@implementation CSLayoutSwitcherWithPreviewWindowController

@synthesize previewRenderer = _previewRenderer;
@synthesize liveRenderer  = _liveRenderer;

-(void)awakeFromNib
{
    self.previewView.showTitle = NO;
    self.previewView.clickable = NO;
    self.liveView.showTitle = NO;
    self.liveView.clickable = NO;

}
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


-(void)setPreviewRenderer:(LayoutRenderer *)previewRenderer
{
    _previewRenderer = previewRenderer;
    self.previewView.useRenderer = _previewRenderer;
    self.previewView.sourceLayout = _previewRenderer.layout;
    if (!_previewRenderer)
    {
        self.previewView.superview.animator.hidden = YES;
        self.liveConstraint.active = NO;
    } else {
        self.previewView.superview.animator.hidden = NO;
        self.liveConstraint.active = YES;
    }
}

-(LayoutRenderer *)previewRenderer
{
    return _previewRenderer;
}

-(void)setLiveRenderer:(LayoutRenderer *)liveRenderer
{
    _liveRenderer = liveRenderer;
    self.liveView.useRenderer = _liveRenderer;
    self.liveView.sourceLayout = _liveRenderer.layout;
}

-(LayoutRenderer *)liveRenderer
{
    return _liveRenderer;
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
