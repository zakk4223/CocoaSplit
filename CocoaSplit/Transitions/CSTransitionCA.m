//
//  CSTransitionCA.m
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import "CSTransitionCA.h"
#import "CSLayoutTransition.h"

@implementation CSTransitionCA




+(NSArray *)subTypes
{
    return @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
}

+(NSString *)transitionCategory
{
    return @"Core Animation";
}


-(NSString *)name
{
    return self.subType;
}


-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{
    CSLayoutTransition *newTransition = [[CSLayoutTransition alloc] init];
    newTransition.transitionName = self.subType;
    if (self.duration)
    {
        newTransition.transitionDuration = [self.duration floatValue];
    }
    
    newTransition.transitionDirection = self.transitionDirection;
    targetLayout.transitionInfo = newTransition;
    return nil;
}

@end
