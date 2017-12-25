//
//  CSSequenceEditorWIndowController.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceEditorWindowController.h"
#import "CSAddSequenceItemPopupViewController.h"
#import "CSSequenceItem.h"
#import "CSSequenceItemLayout.h"
#import "CSSequenceItemTransition.h"
#import "CSSequenceItemWait.h"

#import "AppDelegate.h"

@interface CSSequenceEditorWindowController ()

@end

@implementation CSSequenceEditorWindowController

@synthesize sequence = _sequence;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CSSequenceEditorWindowController"])
    {
        _itemConfigWindows = [NSMutableArray array];
        _itemClasses = [NSMutableArray array];
        
        [_itemClasses addObject:[CSSequenceItemLayout class]];
        [_itemClasses addObject:[CSSequenceItemTransition class]];
        [_itemClasses addObject:[CSSequenceItemWait class]];
    }
    
    return self;
}

-(void) setSequence:(CSLayoutSequence *)sequence
{
    _sequence = sequence;
    self.window.title = [NSString stringWithFormat:@"Script Editor - %@", sequence.name];
}


-(CSLayoutSequence *)sequence
{
    return _sequence;
}


-(void)addSequenceItem:(CSSequenceItem *)newItem
{
    
    
    
    if (newItem)
    {
        NSString *newString = [newItem generateItemScript];
        if (newString)
        {
            NSString *stringWithNL = [NSString stringWithFormat:@"%@\n", newString];
            [self.sequenceTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:stringWithNL]];
            
        }
        
    }
    
    [_addStepPopover close];
}


-(IBAction)openAddStepPopover:(NSButton *)sender
{
    CSAddSequenceItemPopupViewController *vc;
    if (!_addStepPopover)
    {
        _addStepPopover = [[NSPopover alloc] init];
        _addStepPopover.animates = YES;
        _addStepPopover.behavior = NSPopoverBehaviorSemitransient;
    }
    
    Class sequenceClass = [_itemClasses objectAtIndex:sender.tag];
    
    CSSequenceItem *newItem = [[sequenceClass alloc] init];
    
    //if (!_addInputpopOver.contentViewController)
    {
        vc = [[CSAddSequenceItemPopupViewController alloc] initWithSequenceItem:newItem];
        //vc.addOutput = ^void(Class outputClass) {
       //     [self outputPopupButtonAction:outputClass];
      //  };
        
        _addStepPopover.contentViewController = vc;
        //vc.popover = _addOutputpopOver;
        //_addInputpopOver.delegate = vc;
    }
    
    vc.addSequenceItem = ^(CSSequenceItem *sequenceItem) {
    
        [self addSequenceItem:sequenceItem];
    };
    
    
    [_addStepPopover showRelativeToRect:sender.frame ofView:self.window.contentView preferredEdge:NSMaxXEdge];
}


-(void)windowWillClose:(NSNotification *)notification
{
    NSArray *winCopy = _itemConfigWindows.copy;
    
    for (NSWindowController *wc in winCopy)
    {
        [wc close];
    }
    
    if (self.delegate)
    {
        [self.delegate sequenceWindowWillClose:self];
    }
    
}


- (IBAction)saveButtonAction:(id)sender
{
    [self.sequenceObjectController commitEditing];
    if (self.addSequenceOnSave)
    {
        
        AppDelegate *appdel = [NSApp delegate];
        CaptureController *controller = appdel.captureController;
        [controller addSequenceWithNameDedup:self.sequence];
        
    }
    
    [self close];
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self.sequenceObjectController discardEditing];
    [self close];
}
@end
