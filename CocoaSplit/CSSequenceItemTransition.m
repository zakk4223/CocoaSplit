//
//  CSSequenceItemTransition.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemTransition.h"

@implementation CSSequenceItemTransition

@synthesize transitionName = _transitionName;

+(NSString *)label
{
    return @"Transition";
}


-(void)updateItemDescription
{
    NSString *sceneOrNot;
    
    
    if (self.transitionFullScene)
    {
        sceneOrNot = @"entire layout";
    } else {
        sceneOrNot = @"changed inputs";
    }
    
    if (self.transitionFilter)
    {
        self.itemDescription = [NSString stringWithFormat:@"Transition %@, Duration %f using %@", [CIFilter localizedNameForFilterName:self.transitionFilter.name], self.transitionDuration, sceneOrNot];
    } else if (self.transitionName) {
        self.itemDescription = [NSString stringWithFormat:@"Transition %@ direction %@, Duration %f using %@", self.transitionName, self.transitionDirection, self.transitionDuration, sceneOrNot];
    } else {
    
        self.itemDescription = @"Remove transition";
    }
    
}

-(NSString *)generateItemScript
{
     NSString *retString = nil;
    
    if (!self.transitionName && !self.transitionFilter)
    {
        retString = @"clearTransition()";
    } else if (self.transitionFilter) {
        NSArray *inputKeys = self.transitionFilter.inputKeys;
        NSMutableString *blah = [NSMutableString string];
        [blah appendString:@"filter_inputs = {"];
        
        for (NSString *key in inputKeys)
        {
            if ([key isEqualToString:@"inputImage"])
            {
                continue;
            }
            id keyValue = [self.transitionFilter valueForKeyPath:key];
            if (keyValue)
            {
                [blah appendFormat:@"'%@':%@,", key, keyValue];
            }
        }
        
        [blah appendString:@"}\n"];

        NSString *filterName = self.transitionFilter.attributes[kCIAttributeFilterName];
        
        [blah appendFormat:@"setCITransition(name='%@', inputMap=filter_inputs, duration=%f, full_scene=%u)", filterName, self.transitionDuration, self.transitionFullScene];
        
        retString = blah;
    } else {
        retString = [NSString stringWithFormat:@"setBasicTransition(name='%@', direction='%@', duration=%f, full_scene=%u)", self.transitionName, self.transitionDirection, self.transitionDuration, self.transitionFullScene];
    }
    
    return retString;
}




-(void) setTransitionName:(NSString *)transitionName
{
    
    
    _transitionName = transitionName;
    if ([transitionName hasPrefix:@"CI"])
    {
        CIFilter *newFilter = [CIFilter filterWithName:transitionName];
        [newFilter setDefaults];
        self.transitionFilter = newFilter;
    } else {
        self.transitionFilter = nil;
        
    }
    
}




-(NSString *)transitionName
{
    return _transitionName;
}


@end

