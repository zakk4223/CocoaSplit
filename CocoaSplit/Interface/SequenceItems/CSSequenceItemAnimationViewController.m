//
//  CSSequenceItemAnimationViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemAnimationViewController.h"

@interface CSSequenceItemAnimationViewController ()

@end

@implementation CSSequenceItemAnimationViewController


-(instancetype) init
{
    if (self = [self initWithNibName:@"CSSequenceItemAnimationViewController" bundle:nil])
    {
        self.captureController = [CaptureController sharedCaptureController];
        [self loadAnimations];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)loadAnimations
{
    
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];
    
    
    NSDictionary *animations = [runner allAnimations];
    NSMutableArray *tmpList  = [NSMutableArray array];
    
    for (NSString *key in animations)
    {
        [tmpList addObject:key];
        
    }
    
    self.animationList = tmpList;
}


@end
