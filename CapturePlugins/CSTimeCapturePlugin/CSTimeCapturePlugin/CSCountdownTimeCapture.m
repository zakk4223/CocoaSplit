//
//  CSCountdownTimeCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/8/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCountdownTimeCapture.h"

@implementation CSCountdownTimeCapture
@synthesize countdownSeconds = _countdownSeconds;

+(NSString *)label
{
    return @"Time Countdown";
}


-(instancetype)init
{
    if (self = [super init])
    {
        self.countdownSeconds = 300;
        self.restartWhenLive = YES;
        self.endDate = [NSDate dateWithTimeIntervalSinceNow:300];
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.restartWhenLive = [aDecoder decodeBoolForKey:@"restartWhenLive"];
        float countdownVal = [aDecoder decodeFloatForKey:@"countdownSeconds"];
        if (self.restartWhenLive && countdownVal > 0)
        {
            //trigger recalcuation of end date
            self.countdownSeconds = countdownVal;
        } else {
            //don't mess with the end date
            _countdownSeconds = countdownVal;
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.restartWhenLive forKey:@"restartWhenLive"];
    [aCoder encodeFloat:self.countdownSeconds forKey:@"countdownSeconds"];
}

-(float)countdownSeconds
{
    return _countdownSeconds;
}

-(void)setCountdownSeconds:(float)countdownSeconds
{
    _countdownSeconds = countdownSeconds;
    self.endDate = [NSDate dateWithTimeIntervalSinceNow:countdownSeconds];
}


@end
