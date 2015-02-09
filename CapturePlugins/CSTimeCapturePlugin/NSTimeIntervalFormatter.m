/* The MIT License (MIT)

Copyright (c) 2013 Ryan Lovelett

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

/* Taken from: https://github.com/RLovelett/NSTimeIntervalFormatter
 
 Slight modification(s): moved the styles and constants definitions into the two class files
 
 */


#import "NSTimeIntervalFormatter.h"

#import "NSTimeIntervalFormatter.h"


static const uint SECONDS_PER_MINUTE = 60;
static const uint MINUTES_PER_HOUR = 60;
static const uint SECONDS_PER_HOUR = 3600;
static const uint HOURS_PER_DAY = 24;


@implementation NSTimeIntervalFormatter

- (id) init
{
    self = [super init];
    
    NSError* error = nil;
    
    dayRegex = [NSRegularExpression regularExpressionWithPattern:@"D+" options:0 error:&error];
    hourRegex = [NSRegularExpression regularExpressionWithPattern:@"H+" options:0 error:&error];
    minuteRegex = [NSRegularExpression regularExpressionWithPattern:@"M+" options:0 error:&error];
    secondRegex = [NSRegularExpression regularExpressionWithPattern:@"s+" options:0 error:&error];
    milliSecondRegex = [NSRegularExpression regularExpressionWithPattern:@"S+" options:0 error:&error];
    
    return self;
}

- (NSString*) stringFromInterval:(NSTimeInterval) interval
{
    uint wholeSeconds = (uint) interval;
    uint milliseconds = (uint) (fmod(interval, 1.0) * 1000);
    
    char msg[512] = {0};
    
    NSString *message = timeFormat.mutableCopy;
    /*
     timeFormat = [dayRegex
     stringByReplacingMatchesInString:timeFormat
     options:0
     range:timeFormatRange
     withTemplate:format];
     */


    workingRange = timeFormatRange;
    
    if (replace_day)
    {
        uint days = (wholeSeconds / SECONDS_PER_HOUR) / HOURS_PER_DAY;
        [self substituteValue:days forRegex:dayRegex inString:message];
    }
    
    if (replace_hour)
    {
        uint hours = (wholeSeconds / SECONDS_PER_HOUR);
        if (replace_day)
        {
            hours = hours % HOURS_PER_DAY;
        }
        
        [self substituteValue:hours forRegex:hourRegex inString:message];
    }

    if (replace_minute)
    {
        uint minutes = (wholeSeconds / SECONDS_PER_MINUTE);

        if (replace_hour)
        {
            minutes = minutes % MINUTES_PER_HOUR;
        }
        [self substituteValue:minutes forRegex:minuteRegex inString:message];

    }

    if (replace_second)
    {
        uint seconds = wholeSeconds;

        if (replace_minute)
        {
            seconds = seconds  % SECONDS_PER_MINUTE;
        }
        [self substituteValue:seconds forRegex:secondRegex inString:message];
        
    }

    if (replace_msec)
    {
        [self substituteMillis:interval inString:message];
    }

    return message;
}


-(void)substituteMillis:(NSTimeInterval)interval inString:(NSMutableString *)message
{
    NSTextCheckingResult *res;
    
    while (res = [milliSecondRegex firstMatchInString:message options:0 range:workingRange])
    {
        uint length = res.range.length;
        uint milliseconds = (uint) (fmod(interval, 1.0) * pow(10, length));
        
        [message replaceCharactersInRange:res.range withString:[NSString stringWithFormat:@"%0*d", length, milliseconds]];
        workingRange = NSMakeRange(0, message.length);
    }
}


-(void)substituteValue:(uint)value forRegex:(NSRegularExpression *)regex inString:(NSMutableString *)message
{
    NSTextCheckingResult *res;
    
    while (res = [regex firstMatchInString:message options:0 range:workingRange])
    {
        uint length = res.range.length;
        [message replaceCharactersInRange:res.range withString:[NSString stringWithFormat:@"%0*d", length, value]];
        workingRange = NSMakeRange(0, message.length);
    }
}


- (void) setFormat:(NSString*) format
{
    replace_day = replace_hour = replace_minute = replace_msec = replace_second = NO;

    timeFormat = format;
    timeFormatRange = NSMakeRange(0, [timeFormat length]);
    [self extractDayFormat];
    [self extractMilliSecondFormat];
    [self extractSecondFormat];
    [self extractMinuteFormat];
    [self extractHourFormat];
}



- (void) extractDayFormat
{
    NSUInteger numberOfMatches = [dayRegex
                                  numberOfMatchesInString:timeFormat
                                  options:0
                                  range:timeFormatRange];
    
    if (numberOfMatches > 0)
    {
        
        replace_day = YES;
    }
}


- (void) extractHourFormat
{
    NSUInteger numberOfMatches = [hourRegex
                                  numberOfMatchesInString:timeFormat
                                  options:0
                                  range:timeFormatRange];
    
    if (numberOfMatches > 0)
    {
        replace_hour = YES;
    }
}

- (void) extractMinuteFormat
{
    NSUInteger numberOfMatches = [minuteRegex
                                  numberOfMatchesInString:timeFormat
                                  options:0
                                  range:timeFormatRange];
    
    if (numberOfMatches > 0)
    {
        replace_minute = YES;
    }
}

- (void) extractSecondFormat
{
    NSUInteger numberOfMatches = [secondRegex
                                  numberOfMatchesInString:timeFormat
                                  options:0
                                  range:timeFormatRange];
    
    if (numberOfMatches > 0)
    {
        replace_second = YES;
    }
}

- (void) extractMilliSecondFormat
{
    NSUInteger numberOfMatches = [milliSecondRegex
                                  numberOfMatchesInString:timeFormat
                                  options:0
                                  range:timeFormatRange];
    
    if (numberOfMatches > 0)
    {
        replace_msec = YES;
    }
}

@end