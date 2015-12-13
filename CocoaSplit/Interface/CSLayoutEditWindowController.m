//
//  CSLayoutEditWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 10/12/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutEditWindowController.h"

@interface CSLayoutEditWindowController ()

@end

@implementation CSLayoutEditWindowController


-(instancetype) init
{
    return [self initWithWindowNibName:@"CSLayoutEditWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(void)windowWillClose:(NSNotification *)notification
{
    if (self.delegate)
    {
        [self.delegate layoutWindowWillClose:self];
    }
}



- (IBAction)cancelEdit:(id)sender
{
    if (self.layoutController)
    {
        [self.layoutController discardEditing];
    }
    [self close];
}



- (IBAction)editOK:(id)sender
{
    if (self.layoutController)
    {
        [self.layoutController commitEditing];
    }
        
    if (self.previewView.sourceLayout)
    {
        [self.previewView.sourceLayout saveSourceList];
        [self.previewView.sourceLayout clearSourceList];
    }
    [self close];
}

- (IBAction)newSource:(id)sender
{
    [self.previewView addInputSource:self];
}


- (IBAction)openAnimatePopover:(NSButton *)sender
{
    
    CSAnimationChooserViewController *vc;
    if (!_animatepopOver)
    {
        _animatepopOver = [[NSPopover alloc] init];
        
        _animatepopOver.animates = YES;
        _animatepopOver.behavior = NSPopoverBehaviorTransient;
    }
    
    if (!_animatepopOver.contentViewController)
    {
        vc = [[CSAnimationChooserViewController alloc] init];
        
        
        _animatepopOver.contentViewController = vc;
        _animatepopOver.delegate = vc;
        vc.popover = _animatepopOver;
        
    }
    
    vc.sourceLayout = self.previewView.sourceLayout;
    [_animatepopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    NSView *retView = nil;
    
    
    CSAnimationItem *animation = self.previewView.sourceLayout.selectedAnimation;
    
    NSArray *inputs = animation.inputs;
    
    NSDictionary *inputmap = nil;
    
    if (row > -1 && row < inputs.count)
    {
        inputmap = [inputs objectAtIndex:row];
    }
    
    if ([tableColumn.identifier isEqualToString:@"label"])
    {
        
        retView = [tableView makeViewWithIdentifier:@"LabelCellView" owner:self];
    } else if ([tableColumn.identifier isEqualToString:@"value"]) {
        if ([inputmap[@"type"] isEqualToString:@"param"])
        {
            retView = [tableView makeViewWithIdentifier:@"InputParamView" owner:self];
        } else if ([inputmap[@"type"] isEqualToString:@"bool"]) {
            retView = [tableView makeViewWithIdentifier:@"InputBoolView" owner:self];
        } else {
            retView = [tableView makeViewWithIdentifier:@"InputSourceView" owner:self];
        }
    }
    
    return retView;
}


@end
