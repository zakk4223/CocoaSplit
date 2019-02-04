//
//  CSKilobitFormatter.m
//  CocoaSplit
//
//  Created by Zakk on 2/4/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import "CSKilobitFormatter.h"

@implementation CSKilobitFormatter

-(NSString *)stringForObjectValue:(id)obj
{
    NSNumber *totalTime = (NSNumber *)obj;
    Float64 floatBytes = totalTime.floatValue;
    
    Float64 kilobits = floatBytes/1000.0f;

    return [NSString stringWithFormat:@"%.2f kb/sec", kilobits];
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
