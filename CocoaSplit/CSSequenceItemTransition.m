//
//  CSSequenceItemTransition.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemTransition.h"

@implementation CSSequenceItemTransition


+(NSString *)label
{
    return @"Transition";
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


@end

