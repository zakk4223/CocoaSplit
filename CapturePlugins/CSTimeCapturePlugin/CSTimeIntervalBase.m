//
//  CSTimeIntervalBase.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeIntervalBase.h"

@implementation CSTimeIntervalBase
@synthesize format = _format;

-(instancetype)init
{
    if (self = [super init])
    {
        self.styleTypeMap = @{@"None": @(NSTimeIntervalFormatterNoStyle),
                              @"Short": @(NSTimeIntervalFormatterShortStyle),
                              @"Medium": @(NSTimeIntervalFormatterMediumStyle),
                              @"Long": @(NSTimeIntervalFormatterLongStyle),
                              @"Full": @(NSTimeIntervalFormatterFullStyle)
                              };
        self.formatter = [[NSTimeIntervalFormatter alloc] init];
        
        self.format = @"MM:ss.SS";
        
        //[self.formatter setFormat:NSTimeIntervalFormatterMediumStyle];
        
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.endDate = [aDecoder decodeObjectForKey:@"endDate"];
        self.startDate = [aDecoder decodeObjectForKey:@"startDate"];
        self.format = [aDecoder decodeObjectForKey:@"format"];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.endDate forKey:@"endDate"];
    [aCoder encodeObject:self.startDate forKey:@"startDate"];
    [aCoder encodeObject:self.format forKey:@"format"];
}


-(void)setFormat:(NSString *)format
{
    _format = format;
    [self.formatter setFormat:format];
}

-(NSString *)format
{
    return _format;
}


-(NSArray *)styleTypes
{
    return _styleTypeMap.allKeys;
}


-(void)frameTick
{
    NSTimeInterval interval;
    
    if (self.startDate)
    {
        
        interval = -[self.startDate timeIntervalSinceNow];
    } else if (self.endDate) {
        
        interval = [self.endDate timeIntervalSinceNow];
        
    }
    if (interval < 0)
    {
        interval = 0;
    }
    
    self.text = [self.formatter stringFromInterval:interval];
    
}


@end
