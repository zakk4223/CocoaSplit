//
//  CSAnimationWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 8/7/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAnimationWindowController.h"
#import "CaptureController.h"
#import "AppDelegate.h"
#import "PreviewView.h"



@interface CSAnimationWindowController ()

@end

@implementation CSAnimationWindowController

-(instancetype) init
{
    return [self initWithWindowNibName:@"CSAnimationWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}



-(void)showWindow:(id)sender
{
    [super showWindow:sender];
    [self setupLayoutViews];

}

-(void)setupLayoutViews
{
    AppDelegate *appDel = [NSApp delegate];
    
    CaptureController *ccont = appDel.captureController;
    
    self.activePreviewView = ccont.activePreviewView;
    self.livePreviewView = ccont.livePreviewView;
    self.stagingHidden = ccont.stagingHidden;
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
    
    vc.sourceLayout = self.activePreviewView.sourceLayout;
    [_animatepopOver showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
    
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
    NSView *retView = nil;
    
    
    CSAnimationItem *animation = self.activePreviewView.sourceLayout.selectedAnimation;
    
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
