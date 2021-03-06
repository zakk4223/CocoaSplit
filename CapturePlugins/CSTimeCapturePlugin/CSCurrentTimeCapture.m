//
//  CSCurrentTimeCapture.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCurrentTimeCapture.h"

@implementation CSCurrentTimeCapture
@synthesize format = _format;

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


-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    self.formatter.dateStyle = [aDecoder decodeIntegerForKey:@"dateStyle"];
    self.formatter.timeStyle = [aDecoder decodeIntegerForKey:@"timeStyle"];
    
    if ([aDecoder containsValueForKey:@"format"])
    {
        self.format = [aDecoder decodeObjectForKey:@"format"];
    }
}


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];

    [aCoder encodeInteger:self.formatter.dateStyle forKey:@"dateStyle"];
    [aCoder encodeInteger:self.formatter.timeStyle forKey:@"timeStyle"];
    
    if (_format)
    {
        [aCoder encodeObject:_format forKey:@"format"];
    }
}

-(NSImage *)libraryImage
{
    
    NSString *calPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.iCal"];
    
    if (calPath)
    {
        return [[NSWorkspace sharedWorkspace] iconForFile:calPath];
    }
    return nil;
}



+(NSString *)label
{
    return @"Current Date/Time";
}


-(NSString *)saveText
{
    return @"";
}


-(void)setFormat:(NSString *)format
{
    _format = format;
    self.formatter.dateStyle = NSDateFormatterNoStyle;
    self.formatter.timeStyle = NSDateFormatterNoStyle;
    self.formatter.dateFormat = format;
}

-(NSString *)format
{
    return self.formatter.dateFormat;
}


-(NSArray *)styleTypes
{
    return _styleTypeMap.allKeys;
}


-(void)frameTick
{
    NSString *newText = [_formatter stringFromDate:[NSDate date]];
    self.text = newText;
}


+ (NSSet *)keyPathsForValuesAffectingFormat
{
    return [NSSet setWithObjects:@"formatter.dateStyle", @"formatter.timeStyle", nil];

}


@end
