//
//  CSElapsedTimeCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSElapsedTimeCapture.h"
#import "CSPluginServices.h"

@implementation CSElapsedTimeCapture


+(NSString *)label
{
    return @"Elapsed Time";
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.startDate = [NSDate date];
        self.restartWhenLive = NO;
    }
    return self;
}


-(void)frameTick
{
    if (self.useStreamStart)
    {
        self.startDate = [CSPluginServices.sharedPluginServices streamStartDate];
    }
    [super frameTick];
}


-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    self.useStreamStart = [aDecoder decodeObjectForKey:@"useStreamStart"];
    self.restartWhenLive = [aDecoder decodeBoolForKey:@"restartWhenLive"];
    if (self.restartWhenLive)
    {
        self.startDate = [NSDate date];
    }
}

-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    [aCoder encodeBool:self.useStreamStart forKey:@"useStreamStart"];
    [aCoder encodeBool:self.restartWhenLive forKey:@"restartWhenLive"];
}


@end
