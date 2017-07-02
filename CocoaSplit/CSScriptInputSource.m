//
//  CSScriptInputSource.m
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSScriptInputSource.h"
#import "CSScriptInputSourceViewController.h"

@implementation CSScriptInputSource


-(instancetype) init
{
    if (self = [super init])
    {
        [self createUUID];
        self.name = @"SCRIPT TEST";
        self.active = YES;

    }
    
    return self;
}


-(NSViewController *)configurationViewController
{
    CSScriptInputSourceViewController *controller = [[CSScriptInputSourceViewController alloc] init];
    controller.inputSource = self;
    return controller;
}
@end
