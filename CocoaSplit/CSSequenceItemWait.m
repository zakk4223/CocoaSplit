//
//  CSSequenceItemWait.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemWait.h"

@implementation CSSequenceItemWait
-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock
{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.waitTime*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionBlock);
}
@end
