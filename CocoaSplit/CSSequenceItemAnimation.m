//
//  CSSequenceItemAnimation.m
//  CocoaSplit
//
//  Created by Zakk on 3/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemAnimation.h"
#import "CaptureController.h"

@implementation CSSequenceItemAnimation



-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock
{
    
    if (self.animationName)
    {
        
        CSAnimationRunnerObj *animObj = [CaptureController sharedAnimationObj];
        CSAnimationItem *anim = [[CSAnimationItem alloc] initWithDictionary:nil moduleName:self.animationName];
        [sequencer.sourceLayout runSingleAnimation:anim withCompletionBlock:completionBlock];
    }
}
@end
