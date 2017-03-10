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
@synthesize layouts = _layouts;


-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CSLayoutSwitcherWithPreviewWindowController"])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutDeleted:) name:CSNotificationLayoutDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutAdded:) name:CSNotificationLayoutAdded object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSaved:) name:CSNotificationLayoutSaved object:nil];


    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


-(void)windowWillEnterFullScreen:(NSNotification *)notification
{
    [self.transitionView setHidden:YES];
}

-(void)windowWillExitFullScreen:(NSNotification *)notification
{
    [self.transitionView setHidden:NO];
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
        [layoutView.sourceLayout clearSourceList];
        [layoutView removeFromSuperview];
        self.layouts = nil;
    }
}


-(CSLayoutSwitcherView *)findViewForLayout:(SourceLayout *)layout
{
    for (CSLayoutSwitcherView *view in self.gridView.subviews)
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
    NSUInteger layoutidx = 0;
    
    NSUInteger layoutCnt = _layouts.count;
    float countsq = sqrt(layoutCnt);

    NSUInteger nextint = (NSUInteger)ceil(countsq);
    
    NSUInteger columns = nextint;
    NSUInteger rows = ceil(layoutCnt/(float)columns);
    
  
    for (int x = 0; x < _layouts.count; x++)
    {
        
        SourceLayout *layout = [_layouts objectAtIndex:x];
        
        CSLayoutSwitcherView *newView = [self findViewForLayout:layout];
        if (!newView)
        {
     
            newView = [[CSLayoutSwitcherView alloc] init];
        
            newView.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        
            [self.gridView addSubview:newView];
            newView.sourceLayout = layout;
        }
    }
    
    
    [self.gridView setNeedsLayout:YES];
    
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

-(void)windowWillClose:(NSNotification *)notification
{

    self.gridView.subviews = @[];
    for (SourceLayout *layout in self.layouts)
    {
        [layout clearSourceList];
    }
    self.layouts = @[];
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
