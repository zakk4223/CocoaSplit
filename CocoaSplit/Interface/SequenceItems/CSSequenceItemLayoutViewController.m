//
//  CSSequenceItemLayoutViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/19/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemLayoutViewController.h"




@interface CSSequenceItemLayoutViewController ()

@end

@implementation CSSequenceItemLayoutViewController


-(instancetype) init
{
    if (self = [self initWithNibName:@"CSSequenceItemLayoutViewController" bundle:nil])
    {
            self.actionMap = @{@"Switch to Layout": @(kCSLayoutSequenceSwitch),
                                    @"Merge Layout into current": @(kCSLayoutSequenceMerge)
                                    };

        AppDelegate *appDel = [NSApp delegate];
        self.captureController = appDel.captureController;
    }
    
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
