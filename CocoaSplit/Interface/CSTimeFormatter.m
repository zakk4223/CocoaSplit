//
//  CSTimeFormatter.m
//  CocoaSplit
//
//  Created by Zakk on 7/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSTimeFormatter.h"

@implementation CSTimeFormatter

-(NSString *)stringForObjectValue:(id)obj
{
    NSNumber *totalTime = (NSNumber *)obj;
    Float64 floatTime = totalTime.floatValue;
    

    unsigned int minutes = floatTime/60;
    unsigned int seconds = (int)floatTime % 60;
    
    return [NSString stringWithFormat:@"%02u:%02u", minutes, seconds];
}

-(BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString *__autoreleasing  _Nullable *)newString errorDescription:(NSString *__autoreleasing  _Nullable *)error
{
    return YES;
}

-(BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing  _Nullable *)error
{
    return NO;
}


@end
