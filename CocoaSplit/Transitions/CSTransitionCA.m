//
//  CSTransitionCA.m
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import "CSTransitionCA.h"
#import "CSLayoutTransition.h"

@implementation CSTransitionCA



-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionCA *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.transitionDirection = self.transitionDirection;
    }
    return newObj;
}

+(NSArray *)subTypes
{
    NSMutableArray *ret = [NSMutableArray array];
    for (NSString *subType in @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"])
    {
        CSTransitionCA *newTransition = [[CSTransitionCA alloc] init];
        newTransition.subType = subType;
        [ret addObject:newTransition];
    }
    
    return ret;
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
