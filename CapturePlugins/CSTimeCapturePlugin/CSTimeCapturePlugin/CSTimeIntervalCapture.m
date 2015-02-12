//
//  CSTimeIntervalCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/12/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeIntervalCapture.h"

@implementation CSTimeIntervalCapture

@synthesize countdownStart = _countdownStart;

+(NSString *)label
{
    return @"Fixed Time Interval";
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.currentInterval = 0;
        self.countdownStart = 0;
        _lastTime = 0;
        self.format = @"MM:ss.SS";
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeDouble:self.currentInterval forKey:@"currentInterval"];
    [aCoder encodeBool:self.restartWhenLive forKey:@"restartWhenLive"];
    if (self.countdownStart > 0)
    {
        [aCoder encodeDouble:self.countdownStart forKey:@"countdownStart"];
    }
    
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        if ([aDecoder containsValueForKey:@"countdownStart"])
        {
            self.countdownStart = [aDecoder decodeDoubleForKey:@"countdownStart"];
        }
        self.currentInterval = [aDecoder decodeDoubleForKey:@"currentInterval"];
        self.restartWhenLive = [aDecoder decodeBoolForKey:@"restartWhenLive"];
        if (self.restartWhenLive)
        {
            [self reset];
        }
    }
    return self;
}


-(NSTimeInterval)countdownStart
{
    return _countdownStart;
}

-(void)setCountdownStart:(NSTimeInterval)countdownStart
{
    _countdownStart = countdownStart;
    _currentInterval = countdownStart;
    _lastTime = CACurrentMediaTime();
    if (self.paused)
    {
        self.text = [self.formatter stringFromInterval:countdownStart];
    }
}


-(void)setPaused:(bool)paused
{
    if (!paused)
    {
        _lastTime = CACurrentMediaTime();
    }
    
    super.paused = paused;
}


-(void)reset
{
    if (self.countdownStart)
    {
        _currentInterval = self.countdownStart;
    } else {
        _currentInterval = 0.0f;
    }
}


-(void)frameTick
{
    if (self.paused)
    {
        return;
    }
    
    
    NSTimeInterval interval = 0;
    
    if (!_lastTime)
    {
        _lastTime = CACurrentMediaTime();
        self.currentInterval = 0;
    } else {
        CFTimeInterval now = CACurrentMediaTime();
        NSTimeInterval elapsed = now - _lastTime;
        _lastTime = now;
        if (_countdownStart > 0)
        {
            _currentInterval -= elapsed;
        } else {
            _currentInterval += elapsed;
        }
        interval = _currentInterval;
        
    }
    if (interval < 0)
    {
        interval = 0;
    }
    
    
    self.text = [self.formatter stringFromInterval:interval];
}


@end
