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
    return [self initWithWindowNibName:@"CSLayoutSwitcherWithPreviewWindowController"];
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
    
  
    /*
    for (int r = rows-1; r >= 0; r--)
    {
        
        
        for (int c = 0; c < columns; c++)
        {
            
            if (layoutidx < _layouts.count)
            {
                
                
                
            CSPreviewGLLayer *layoutView = [CSPreviewGLLayer layer];
            layoutView.borderWidth = 2.0f;
            layoutView.borderColor = [NSColor redColor].CGColor;
            [layoutView addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth relativeTo:@"superlayer" attribute:kCAConstraintWidth scale:1.0/columns offset:0]];
            [layoutView addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintHeight relativeTo:@"superlayer" attribute:kCAConstraintHeight scale:1.0/rows offset:0]];
            [layoutView addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMaxX scale:c/(float)columns offset:0]];
            [layoutView addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY relativeTo:@"superlayer" attribute:kCAConstraintMaxY scale:r/(float)rows offset:0]];
                SourceLayout *useLayout = [_layouts objectAtIndex:layoutidx];
                layoutView.doRender = YES;
                layoutView.renderer = [[LayoutRenderer alloc] init];
                layoutView.renderer.layout = useLayout;
                [layoutView setActions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"bounds",nil]];
                [useLayout restoreSourceList:nil];
                layoutidx++;
                [self.gridView.layer addSublayer:layoutView];

            }
        }
    }*/

    for (int x = 0; x < _layouts.count; x++)
    {
        CSLayoutSwitcherView *newButton = [[CSLayoutSwitcherView alloc] init];
        
        newButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        SourceLayout *layout = [_layouts objectAtIndex:x];
        
        
        [self.gridView addSubview:newButton];
        newButton.sourceLayout = layout;

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
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
