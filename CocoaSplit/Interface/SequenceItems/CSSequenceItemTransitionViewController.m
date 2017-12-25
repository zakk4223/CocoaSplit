//
//  CSSequenceItemTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/20/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemTransitionViewController.h"
#import "CSSequenceItemTransition.h"

@interface CSSequenceItemTransitionViewController ()

@end

@implementation CSSequenceItemTransitionViewController


-(instancetype)init
{
    if (self = [self initWithNibName:@"CSSequenceItemTransitionViewController" bundle:nil])
    {
        self.captureController = [CaptureController sharedCaptureController];
    }
    return self;
}


-(IBAction)openTransitionFilterPanel:(NSButton *)sender
{
    
    CSSequenceItemTransition *myItem = (CSSequenceItemTransition *)self.sequenceItem;
    
    
    if (!myItem || !myItem.transitionFilter)
    {
        return;
    }
    
    IKFilterUIView *filterView = [myItem.transitionFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey, kCIInputTargetImageKey, kCIInputTimeKey]];
    
    
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
