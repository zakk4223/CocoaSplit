//
//  CSTransitionCA.m
//  CocoaSplit
//
//  Created by Zakk on 3/16/18.
//

#import "CSTransitionCA.h"
#import "CSLayoutTransition.h"
#import "CSSimpleLayoutTransitionViewController.h"

@implementation CSTransitionCA


-(instancetype) init
{
    if (self = [super init])
    {
        self.timingFunction = kCAMediaTimingFunctionDefault;
        self.timingFunctions = @{@"Default": kCAMediaTimingFunctionDefault,
                                 @"Linear": kCAMediaTimingFunctionLinear,
                                 @"Ease In": kCAMediaTimingFunctionEaseIn,
                                 @"Ease Out": kCAMediaTimingFunctionEaseOut,
                                 @"Ease In and Out": kCAMediaTimingFunctionEaseInEaseOut
                                 };
    }
    
    return self;
}
    
    
-(id)copyWithZone:(NSZone *)zone
{
    CSTransitionCA *newObj = [super copyWithZone:zone];
    if (newObj)
    {
        newObj.transitionDirection = self.transitionDirection;
        newObj.wholeLayout = self.wholeLayout;
        newObj.timingFunction = self.timingFunction;
    }
    return newObj;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.transitionDirection forKey:@"transitionDirection"];
    [aCoder encodeBool:self.wholeLayout forKey:@"wholeLayout"];
    [aCoder encodeObject:self.timingFunction forKey:@"timingFunction"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.transitionDirection = [aDecoder decodeObjectForKey:@"transitionDirection"];
        self.wholeLayout = [aDecoder decodeBoolForKey:@"wholeLayout"];
        self.timingFunction = [aDecoder decodeObjectForKey:@"timingFunction"];
        if (!self.timingFunction)
        {
            self.timingFunction = kCAMediaTimingFunctionDefault;
        }
    }
    
    return self;
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


-(NSViewController<CSLayoutTransitionViewProtocol> *)configurationViewController
{
    CSSimpleLayoutTransitionViewController *vc = [[CSSimpleLayoutTransitionViewController alloc] init];
    vc.transition = self;
    return vc;
}


-(NSString *)name
{
    
    NSString *ret = [super name];
    if (!ret)
    {
        ret = self.subType;
    }
    return ret;
}


//var createTransition = function(ca_transition, wholeScene) {

-(NSString *)preChangeAction:(SourceLayout *)targetLayout
{

    CATransition *newTransition = [CATransition animation];
    newTransition.type = self.subType;
    newTransition.subtype = self.transitionDirection;
    newTransition.duration = self.duration.floatValue;
    newTransition.removedOnCompletion = YES;
    newTransition.timingFunction = [CAMediaTimingFunction functionWithName:self.timingFunction];
    self.realTransition = newTransition;
    
    return @"return createTransition(self.realTransition, self.wholeLayout);";
}

@end
