//
//  CSAudioInputSourceViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSAudioInputSourceViewController.h"

@interface CSAudioInputSourceViewController ()

@end

@implementation CSAudioInputSourceViewController


-(instancetype) init
{
    if (self = [super initWithNibName:@"CSAudioInputSourceViewController" bundle:nil])
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



-(IBAction)openMixerWindow:(id)sender
{

    CAMultiAudioInput *inputNode = nil;
    
    inputNode = [self.inputSource findAudioNodeForEdit];
    

    if (inputNode)
    {
        self.mixerWindow = [[CAMultiAudioMatrixMixerWindowController alloc] initWithAudioMixer:inputNode];
        [self.mixerWindow showWindow:nil];
        self.mixerWindow.delegate = self;
        self.mixerWindow.window.title = self.inputSource.name;
    }
}

-(void)mixerWindowWillClose:(CAMultiAudioMatrixMixerWindowController *)mixerController
{
    NSMutableDictionary *saveData = [NSMutableDictionary dictionary];
    CAMultiAudioInput *inputNode = mixerController.audioNode;
    [inputNode saveDataToDict:saveData];
    self.inputSource.savedAudioSettings = saveData;
}



-(void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    
    
    NSString *scriptKey = self.scriptKeys[tableView.selectedRow];
    [self.textView bind:@"value" toObject:self.inputSourceController withKeyPath:scriptKey options:nil];
    
    
}

@end
