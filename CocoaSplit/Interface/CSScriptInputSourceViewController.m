//
//  CSScriptInputSourceViewController.m
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSScriptInputSourceViewController.h"

@interface CSScriptInputSourceViewController ()

@end

@implementation CSScriptInputSourceViewController


-(instancetype) init
{
    if (self = [super initWithNibName:@"CSScriptInputSourceViewController" bundle:nil])
    {
        self.scriptTypes = @[@"After Add", @"Before Delete", @"FrameTick", @"Before Merge", @"After Merge", @"Before Remove", @"Before Replace", @"After Replace"];
        self.scriptKeys = @[@"selection.script_afterAdd", @"selection.script_beforeDelete", @"selection.script_frameTick", @"selection.script_beforeMerge", @"selection.script_afterMerge", @"selection.script_beforeRemove", @"selection.script_beforeReplace", @"selection.script_afterReplace"];
        
    }

    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


- (IBAction)saveButtonAction:(id)sender
{
    [self.inputSourceController commitEditing];
    [self.view.window close];
    
}

-(void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    
    
    NSString *scriptKey = self.scriptKeys[tableView.selectedRow];
    [self.textView bind:@"value" toObject:self.inputSourceController withKeyPath:scriptKey options:nil];
    
    
}

@end
