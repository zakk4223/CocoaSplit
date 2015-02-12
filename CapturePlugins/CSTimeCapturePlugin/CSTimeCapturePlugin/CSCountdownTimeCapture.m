//
//  CSCountdownTimeCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/8/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCountdownTimeCapture.h"

@implementation CSCountdownTimeCapture

+(NSString *)label
{
    return @"Countdown until time";
}


-(instancetype)init
{
    if (self = [super init])
    {
        self.endDate = [NSDate dateWithTimeIntervalSinceNow:300];
    }
    
    return self;
}


@end
