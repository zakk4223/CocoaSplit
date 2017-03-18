//
//  CSSequenceActivatorViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceActivatorViewController.h"
#import "AppDelegate.h"
#import "CaptureController.h"

@interface CSSequenceActivatorViewController ()

@end

@implementation CSSequenceActivatorViewController
@synthesize sequences = _sequences;


-(instancetype) init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceDeleted:) name:CSNotificationSequenceDeleted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sequenceAdded:) name:CSNotificationSequenceAdded object:nil];
        
        
    }
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/*
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
*/

-(void)sequenceAdded:(NSNotification *)notification
{
    NSLog(@"SEQUNCE ADDED!!");
    self.sequences = nil;
}


-(void)sequenceDeleted:(NSNotification *)notification
{
    SourceLayout *layout = notification.object;
    
    self.sequences = nil;
}



-(CSSequenceActivatorView *)findViewForSequence:(CSLayoutSequence *)sequence
{
    for (CSSequenceActivatorView *view in self.view.subviews)
    {
        if (view.layoutSequence && view.layoutSequence == sequence)
        {
            return view;
        }
    }
    
    return nil;
}


-(NSArray *)sequences
{
    return _sequences;
}


-(void)setSequences:(NSArray *)sequences
{
    if (sequences == nil)
    {
        AppDelegate *appDel = NSApp.delegate;
        
        CaptureController *controller = appDel.captureController;
        _sequences = controller.layoutSequences;
        NSLog(@"SEQUENCES %@", _sequences);
        
    } else {
        _sequences = sequences;
    }
    
    for (NSView *subview in self.view.subviews.copy)
    {
        [subview removeFromSuperview];
    }

    
    for (int x = 0; x < _sequences.count; x++)
    {
        
        CSLayoutSequence *sequence = [_sequences objectAtIndex:x];
        
        CSSequenceActivatorView *newView = [self findViewForSequence:sequence];
        if (!newView)
        {
            
            newView = [[CSSequenceActivatorView alloc] init];
            
            newView.translatesAutoresizingMaskIntoConstraints = NO;
            
            
            
            [self.view addSubview:newView];
            NSLog(@"ADDED %@ TO %@", newView, self.view);
            newView.layoutSequence = sequence;
            newView.controller = self;
        }
    }
    
    
    [self.view setNeedsLayout:YES];
    
}


@end
