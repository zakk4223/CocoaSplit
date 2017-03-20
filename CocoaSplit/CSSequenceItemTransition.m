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
-(void)clearTransition
{
    self.transitionName = nil;
    self.transitionDirection = nil;
    self.transitionFilter = nil;
    self.transitionDuration = 0;
}

-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock
{
    SourceLayout *layout = sequencer.sourceLayout;
    layout.transitionName = self.transitionName;
    layout.transitionDirection = self.transitionDirection;
    layout.transitionFilter = self.transitionFilter;
    layout.transitionDuration = self.transitionDuration;
    layout.transitionFullScene = self.transitionFullScene;
    if (completionBlock)
    {
        completionBlock();
    }
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

