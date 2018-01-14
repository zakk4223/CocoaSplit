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
        self.name = @"Scripts";
        self.active = YES;
        self.scriptPriority = 9999;

    }
    
    return self;
}


-(instancetype)copyWithZone:(NSZone *)zone
{
    CSScriptInputSource *newCopy = [super copyWithZone:zone];
    return newCopy;
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    self.scriptPriority = 9999;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.name forKey:@"name"];

}

-(NSString *)label
{
    return @"Script";
}

-(bool) isScript
{
    return YES;
}

-(NSViewController *)configurationViewController
{
    CSScriptInputSourceViewController *controller = [[CSScriptInputSourceViewController alloc] init];
    controller.inputSource = self;
    return controller;
}
@end
