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
#import "PreviewView.h"

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
            _queuedSequences = [NSMutableArray array];
            
        }
        return self;
    }
    
    
-(void)dealloc
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    
    
-(void)sequenceAdded:(NSNotification *)notification
    {
        self.sequences = nil;
    }
    
    
-(void)sequenceDeleted:(NSNotification *)notification
    {
        
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
                newView.layoutSequence = sequence;
                newView.controller = self;
            }
        }
        
        
        [self.view setNeedsLayout:YES];
        
    }
    

-(void)editSequence:(NSMenuItem *) sender
{
    
    CaptureController *controller = [CaptureController sharedCaptureController];
    
    CSLayoutSequence *toEdit = sender.representedObject;
    [controller openSequenceWindow:toEdit];
    
    //[self.captureController openLayoutPopover:self.layoutButton forLayout:toEdit];
}


-(void)deleteSequence:(NSMenuItem *) sender
    {
        
        
        CaptureController *controller = [CaptureController sharedCaptureController];
        CSLayoutSequence *toDelete = sender.representedObject;
        
        [controller deleteSequence:toDelete];
        
    }
    
    
    
    
-(void)buildSequenceMenuForView:(CSSequenceActivatorView *)view
    {
        
        NSInteger idx = 0;
        
        NSMenuItem *tmp;
        CSLayoutSequence *forSequence = view.layoutSequence;
        
        self.sequenceMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
        tmp = [self.sequenceMenu insertItemWithTitle:@"Edit" action:@selector(editSequence:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forSequence;

        tmp = [self.sequenceMenu insertItemWithTitle:@"Delete" action:@selector(deleteSequence:) keyEquivalent:@"" atIndex:idx++];
        tmp.target = self;
        tmp.representedObject = forSequence;
        
        
    }
    
    
    
-(void)showSequenceMenu:(NSEvent *)clickEvent forView:(CSSequenceActivatorView *)view
{
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildSequenceMenuForView:view];
    [self.sequenceMenu popUpMenuPositioningItem:self.sequenceMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}

-(void)handleScriptException:(NSException *)exception
{
    
    NSDictionary *errorUserInfo = @{
                                    NSLocalizedDescriptionKey: exception.reason,
                                    NSLocalizedFailureReasonErrorKey: exception.name
                                    };
    
    NSError *pyError = [NSError errorWithDomain:@"zakk.lol.cocoasplit" code:-35 userInfo:errorUserInfo];
    NSAlert *errAlert = [NSAlert alertWithError:pyError];
    dispatch_async(dispatch_get_main_queue(), ^{
        [errAlert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:nil];
        
    });
}


-(void)sequenceViewClicked:(NSEvent *)clickEvent forView:(CSSequenceActivatorView *)view
{
    view.layer.opacity = 0.5f;
    
    if ([clickEvent modifierFlags] & NSShiftKeyMask)
    {
        if (view.isQueued)
        {
            view.isQueued = NO;
            [self.queuedSequences removeObject:view];
        } else {
            view.isQueued = YES;
            [self.queuedSequences addObject:view];

        }
    } else {

        if (view.layoutSequence)
        {
            CaptureController *captureController = [CaptureController sharedCaptureController];
            if (view.layoutSequence.lastRunUUID)
            {
                [view.layoutSequence cancelSequenceForLayout:captureController.activePreviewView.sourceLayout];
            } else {
                if (self.queuedSequences.count > 0)
                {
                    for (CSSequenceActivatorView *qView in self.queuedSequences)
                    {
                        [qView.layoutSequence runSequenceForLayout:captureController.activePreviewView.sourceLayout withCompletionBlock:^(){qView.layer.opacity = 1.0f; qView.isQueued = NO;} withExceptionBlock:^(NSException *exception) {
                            [self handleScriptException:exception];
                        }];

                    }
                    [self.queuedSequences removeAllObjects];
                }
                [view.layoutSequence runSequenceForLayout:captureController.activePreviewView.sourceLayout withCompletionBlock:^(){NSLog(@"ANIMATION DONE");view.layer.opacity = 1.0f; view.isQueued = NO;} withExceptionBlock:^(NSException *exception) {
                    [self handleScriptException:exception];
                }];
            }
        }
    }

}
@end
