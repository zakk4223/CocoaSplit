//
//  CSTimeCaptureBase.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeCaptureBase.h"

@implementation CSTimeCaptureBase

-(instancetype)init
{
    if (self = [super init])
    {
        self.styleTypeMap = @{@"None": @(NSDateFormatterNoStyle),
                              @"Short": @(NSDateFormatterShortStyle),
                              @"Medium": @(NSDateFormatterMediumStyle),
                              @"Long": @(NSDateFormatterLongStyle),
                              @"Full": @(NSDateFormatterFullStyle)
                              };
        self.formatter = [[NSDateFormatter alloc] init];
        
        self.formatter.dateStyle = NSDateFormatterMediumStyle;
        self.formatter.timeStyle = NSDateFormatterMediumStyle;
        //self.formatter.dateFormat = @"mm:ss.SS";
    }
    return self;
}




-(NSArray *)styleTypes
{
    return _styleTypeMap.allKeys;
}


-(void)frameTick
{
    NSDate *displayDate;
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    if (self.startDate)
    {
        
        NSTimeInterval interval = -[self.startDate timeIntervalSinceNow];
    } else if (self.endDate) {
        
        NSTimeInterval interval = [self.endDate timeIntervalSinceNow];
        
    } else {
        displayDate = [NSDate date];
    }
    
    
    self.text = [_formatter stringFromDate:displayDate];
}


@end
