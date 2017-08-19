//
//  CSCIFilterLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSCIFilterLayoutTransitionViewController.h"

@interface CSCIFilterLayoutTransitionViewController ()

@end

@implementation CSCIFilterLayoutTransitionViewController


-(instancetype) init
{
    if ([self initWithNibName:@"CSCIFilterLayoutTransitionViewController" bundle:nil])
    {
        
    }
    
    return self;
}


-(IBAction)openTransitionFilterPanel:(NSButton *)sender
{
    
    
    if (!self.transition.transitionFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [self.transition.transitionFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
    self.transitionFilterWindow = [[NSWindow alloc] init];
    [self.transitionFilterWindow setContentSize:filterView.bounds.size];
    [self.transitionFilterWindow.contentView addSubview:filterView];
    
    self.transitionFilterWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    [self.transitionFilterWindow setReleasedWhenClosed:NO];
    
    [self.transitionFilterWindow makeKeyAndOrderFront:self.transitionFilterWindow];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
