//
//  CSCurrentTimeCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCurrentTimeCapture.h"

@implementation CSCurrentTimeCapture



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


+(NSString *)label
{
    return @"Current Date/Time";
}

-(NSArray *)styleTypes
{
    return _styleTypeMap.allKeys;
}


-(void)frameTick
{
    self.text = [_formatter stringFromDate:[NSDate date]];
}


@end
