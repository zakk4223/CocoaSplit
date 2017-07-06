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

@end
