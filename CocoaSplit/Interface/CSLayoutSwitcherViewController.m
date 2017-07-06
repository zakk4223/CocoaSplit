//
//  CSLayoutSwitcherViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSwitcherViewController.h"
#import "CaptureController.h"
#import "AppDelegate.h"
#import "CSLayoutRecorder.h"

@interface CSLayoutSwitcherViewController ()

@end

@implementation CSLayoutSwitcherViewController
@synthesize layouts = _layouts;


-(instancetype) init
{
    if (self = [super init])
    {
        self.isSwitcherView = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutDeleted:) name:CSNotificationLayoutDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutAdded:) name:CSNotificationLayoutAdded object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSaved:) name:CSNotificationLayoutSaved object:nil];
        
        
    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (SourceLayout *layout in self.layouts)
    {
        if (!layout.recorder || !layout.recorder.recordingActive)
        {
            [layout clearSourceList];
        }
    }
}



-(void)layoutSaved:(NSNotification *)notification
{
    SourceLayout *layout = notification.object;
    
    CSLayoutSwitcherView *layoutView = [self findViewForLayout:layout];
    if (layoutView)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [layout clearSourceList];
            [layout restoreSourceList:nil];
            [layoutView setNeedsLayout:YES];
            
        });
    }
}


-(void)layoutAdded:(NSNotification *)notification
{
    self.layouts = nil;
}


-(void)layoutDeleted:(NSNotification *)notification
{
    SourceLayout *layout = notification.object;
    
    CSLayoutSwitcherView *layoutView = [self findViewForLayout:layout];
    
    if (layoutView)
    {
        //[layoutView.sourceLayout clearSourceList];
        [layoutView removeFromSuperview];
        self.layouts = nil;
    }
}


-(CSLayoutSwitcherView *)findViewForLayout:(SourceLayout *)layout
{
    for (CSLayoutSwitcherView *view in self.view.subviews)
    {
        if (view.sourceLayout && view.sourceLayout == layout)
        {
            return view;
        }
    }
    
    return nil;
}


-(NSArray *)layouts
{
    return _layouts;
}

-(void)setLayouts:(NSArray *)layouts
{
    if (layouts == nil)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        _layouts = controller.sourceLayouts;
        
    } else {
        _layouts = layouts;
    }
    
    for (NSView *subview in self.view.subviews.copy)
    {
        [subview removeFromSuperview];
    }
    
    
    for (int x = 0; x < _layouts.count; x++)
    {
        
        SourceLayout *layout = [_layouts objectAtIndex:x];
        
        CSLayoutSwitcherView *newView = [self findViewForLayout:layout];
        if (!newView)
        {
            
            newView = [[CSLayoutSwitcherView alloc] initWithIsSwitcherView:self.isSwitcherView];
            
            newView.translatesAutoresizingMaskIntoConstraints = NO;
            
            
            
            [self.view addSubview:newView];
            newView.sourceLayout = layout;
            newView.controller = self;
        }
    }
    
    
    [self.view setNeedsLayout:YES];
    
}

-(void)layoutClicked:(SourceLayout *)layout withEvent:(NSEvent *)event
{
    
    if (layout)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        [controller switchToLayout:layout];
    }
    
}







-(void)saveToLayout:(NSMenuItem *) sender
{
    
    SourceLayout *toSave = sender.representedObject;
    AppDelegate *appDel = NSApp.delegate;
    
    CaptureController *controller = appDel.captureController;
    [controller saveToLayout:toSave];
}


-(void)editLayout:(NSMenuItem *) sender
{
    AppDelegate *appDel = NSApp.delegate;
    
    CaptureController *controller = appDel.captureController;

    SourceLayout *toEdit = sender.representedObject;
    [controller openLayoutWindow:toEdit];
    
    //[self.captureController openLayoutPopover:self.layoutButton forLayout:toEdit];
}


-(void)deleteLayout:(NSMenuItem *) sender
{
    
    AppDelegate *appDel = NSApp.delegate;
    
    CaptureController *controller = appDel.captureController;

    SourceLayout *toDelete = sender.representedObject;
    
    [controller deleteLayout:toDelete];
    
}


-(void) startRecordingLayout:(NSMenuItem *)sender
{
    [[CaptureController sharedCaptureController] startRecordingLayout:sender.representedObject];
}


-(void) stopRecordingLayout:(NSMenuItem *)sender
{
    [[CaptureController sharedCaptureController] stopRecordingLayout:sender.representedObject];
}


-(void)buildLayoutMenuForView:(CSLayoutSwitcherView *)view
{
    
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    SourceLayout *forLayout = view.sourceLayout;
    
    self.layoutMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    tmp = [self.layoutMenu insertItemWithTitle:@"Save To" action:@selector(saveToLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;

    if (forLayout.recordingLayout)
    {
        tmp = [self.layoutMenu insertItemWithTitle:@"Stop Recording" action:@selector(stopRecordingLayout:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forLayout;

    } else {
        tmp = [self.layoutMenu insertItemWithTitle:@"Start Recording" action:@selector(startRecordingLayout:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forLayout;

    }
    tmp = [self.layoutMenu insertItemWithTitle:@"Edit" action:@selector(editLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;

    tmp = [self.layoutMenu insertItemWithTitle:@"Delete" action:@selector(deleteLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp.representedObject = forLayout;

    
}

-(void)showLayoutMenu:(NSEvent *)clickEvent forView:(CSLayoutSwitcherView *)view
{
    if (self.isSwitcherView)
    {
        return;
    }
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildLayoutMenuForView:view];
    [self.layoutMenu popUpMenuPositioningItem:self.layoutMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}





@end
