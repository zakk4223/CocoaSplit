//
//  CSSimpleLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/16/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSimpleLayoutTransitionViewController.h"

@interface CSSimpleLayoutTransitionViewController ()

@end

@implementation CSSimpleLayoutTransitionViewController


-(instancetype) init
{
    if ([self initWithNibName:@"CSSimpleLayoutTransitionViewController" bundle:nil])
    {
        self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];

    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
