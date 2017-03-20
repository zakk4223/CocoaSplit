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
#import "AppDelegate.h"

@interface CSSequenceEditorWindowController ()

@end

@implementation CSSequenceEditorWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype) init
{
    if (self = [self initWithWindowNibName:@"CSSequenceEditorWindowController"])
    {
        _itemConfigWindows = [NSMutableArray array];
    }
    
    return self;
}


-(void)addSequenceItemByClass:(Class) sequenceClass
{
    
    CSSequenceItem *newItem = [[sequenceClass alloc] init];
    
    CSSequenceItemEditorWindowController *newController = [[CSSequenceItemEditorWindowController alloc] init];
    
    [newController openWithItem:newItem usingCloseBlock:^(CSSequenceItemEditorWindowController *controller) {
        
        if (controller.saveItemRequested)
        {
            [self.sequenceItemsArrayController addObject:controller.editItem];

        }
        
        controller.editItem = nil;
        if ([_itemConfigWindows containsObject:controller])
        {
            [_itemConfigWindows removeObject:controller];
        }
    }];
    
    [_itemConfigWindows addObject:newController];
    //Pop up configuration window with item.
    
}


-(void)openAddStepPopover:(id)sender sourceRect:(NSRect)sourceRect
{
    CSAddSequenceItemPopupViewController *vc;
    if (!_addStepPopover)
    {
        _addStepPopover = [[NSPopover alloc] init];
        _addStepPopover.animates = YES;
        _addStepPopover.behavior = NSPopoverBehaviorTransient;
    }
    
    //if (!_addInputpopOver.contentViewController)
    {
        vc = [[CSAddSequenceItemPopupViewController alloc] init];
        //vc.addOutput = ^void(Class outputClass) {
       //     [self outputPopupButtonAction:outputClass];
      //  };
        
        _addStepPopover.contentViewController = vc;
        //vc.popover = _addOutputpopOver;
        //_addInputpopOver.delegate = vc;
    }
    
    vc.addSequenceItem = ^(Class sequenceItem) {
    
        [self addSequenceItemByClass:sequenceItem];
    };
    
    
    [_addStepPopover showRelativeToRect:sourceRect ofView:self.window.contentView preferredEdge:NSMaxXEdge];
}


-(void)windowWillClose:(NSNotification *)notification
{
    NSArray *winCopy = _itemConfigWindows.copy;
    
    for (NSWindowController *wc in winCopy)
    {
        [wc close];
    }
}


- (IBAction)itemSegmentControlClicked:(NSSegmentedControl *)sender {

    NSPoint mousePoint = [self.window mouseLocationOutsideOfEventStream];
    NSRect sourceRect = NSMakeRect(mousePoint.x, mousePoint.y, 2.0f, 2.0f);

    switch (sender.tag) {
        case 0:
            [self openAddStepPopover:sender sourceRect:sourceRect];
            break;
            
        default:
            break;
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
