//
//  CSSequenceItemWait.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemWait.h"

@implementation CSSequenceItemWait

+(NSString *)label
{
    return @"Wait";
}


-(NSString *)generateItemScript
{
    NSMutableString *animationCode = [NSMutableString string];
    
    if (self.waitForAnimations)
    {
        [animationCode appendString:@"waitAnimation("];
        if (self.waitTime > 0)
        {
            [animationCode appendFormat:@"%f", self.waitTime];
        }
        
        [animationCode appendString:@")"];
        
    } else {
        [animationCode appendString:@"wait("];
        if (self.waitTime > 0)
        {
            [animationCode appendFormat:@"%f", self.waitTime];
        }
        [animationCode appendString:@")"];
    }
    
    return animationCode;
}

-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)(void))completionBlock
{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.waitTime*NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), completionBlock);
}

-(void)updateItemDescription
{
    self.itemDescription = [NSString stringWithFormat:@"Wait: %f seconds", self.waitTime];
}

@end
