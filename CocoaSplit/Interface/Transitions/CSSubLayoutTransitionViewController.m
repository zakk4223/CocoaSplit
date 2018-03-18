//
//  CSSubLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSubLayoutTransitionViewController.h"
#import "CaptureController.h"
#import "CSCIFilterLayoutTransitionViewController.h"
#import "CSLayoutLayoutTransitionViewController.h"
#import "CSSimpleLayoutTransitionViewController.h"


@interface CSSubLayoutTransitionViewController ()

@end

@implementation CSSubLayoutTransitionViewController
@synthesize transitionName = _transitionName;
@synthesize transition = _transition;


-(instancetype) init
{
    if ([self initWithNibName:@"CSSubLayoutTransitionViewController" bundle:nil])
    {
        self.transitionNames = [CaptureController sharedCaptureController].transitionNames;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(CSLayoutTransition *) transition
{
    return _transition;
}

-(void)setTransition:(CSLayoutTransition *)transition
{
    /*
    _transition = transition;

    if (transition)
    {
        self.transitionName = transition.transitionName;
    } else {
        self.transitionName = nil;
    }*/
    
}


-(void) setTransitionName:(NSString *)transitionName
{
    /*
    
    _transitionName = transitionName;
    
    
    if (!transitionName)
    {
        self.layoutTransitionViewController = nil;
    } else if ([transitionName hasPrefix:@"CI"]) {
        CIFilter *newFilter = [CIFilter filterWithName:transitionName];
        [newFilter setDefaults];
        self.layoutTransitionViewController = nil;
        self.layoutTransitionViewController = [[CSCIFilterLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = self.transition;
        self.layoutTransitionViewController.transition.transitionFilter = newFilter;
        self.layoutTransitionViewController.transition.transitionName = transitionName;

    } else if ([transitionName isEqualToString:@"Layout"]) {
        self.layoutTransitionViewController = nil;
        self.layoutTransitionViewController = [[CSLayoutLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = self.transition;
        self.layoutTransitionViewController.transition.transitionName = transitionName;


    } else {
        self.layoutTransitionViewController = [[CSSimpleLayoutTransitionViewController alloc] init];
        self.layoutTransitionViewController.transition = self.transition;
        self.layoutTransitionViewController.transition.transitionName = transitionName;
    }
    [self changeTransitionView];
     */
}




-(void)changeTransitionView
{
    self.layoutTransitionConfigView.subviews = @[];
    if (self.layoutTransitionViewController)
    {
        self.layoutTransitionViewController.view.frame = self.layoutTransitionConfigView.bounds;
        [self.layoutTransitionConfigView addSubview:self.layoutTransitionViewController.view];
    }
    
}


-(NSString *)transitionName
{
    return _transitionName;
}


-(void)popoverWillClose:(NSNotification *)notification
{
    [self commitEditing];
}


@end
